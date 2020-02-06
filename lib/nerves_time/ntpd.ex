defmodule NervesTime.Ntpd do
  use GenServer
  require Logger

  @moduledoc false

  # If restarting ntpd due to a crash, delay its start to avoid pegging
  # ntp servers. This delay can be long since the clock has either been
  # set (i.e., it's not far off from the actual time) or there is a problem
  # setting the time that has a low probability of being fixed by trying
  # again immediately. Plus ntp server admins get annoyed by misbehaving
  # IoT devices pegging their servers and we don't want that.
  @ntpd_restart_delay 60_000
  @ntpd_clean_start_delay 10

  @default_ntpd_path "/usr/sbin/ntpd"
  @default_ntp_servers [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  @default_rtc {NervesTime.FileTime, []}

  defmodule State do
    @moduledoc false
    @type t() :: %__MODULE__{
            socket: :gen_udp.socket(),
            servers: [String.t()],
            daemon: nil | pid(),
            synchronized?: boolean(),
            clean_start?: boolean(),
            rtc: module(),
            rtc_state: term()
          }
    defstruct socket: nil,
              servers: [],
              daemon: nil,
              synchronized?: false,
              clean_start?: true,
              rtc: nil,
              rtc_state: nil
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Return whether ntpd has synchronized with a time server
  """
  @spec synchronized?() :: boolean()
  def synchronized?() do
    GenServer.call(__MODULE__, :synchronized?)
  end

  @doc """
  Return whether ntpd was started cleanly

  If ntpd crashes or this GenServer crashes, then the run is considered
  unclean and there's a delay in starting ntpd. This is intended to
  prevent abusive polling of public ntpd servers.
  """
  @spec clean_start?() :: boolean()
  def clean_start?() do
    GenServer.call(__MODULE__, :clean_start?)
  end

  @doc """
  Update the list of NTP servers to poll
  """
  @spec set_ntp_servers([String.t()]) :: :ok
  def set_ntp_servers(servers) when is_list(servers) do
    GenServer.call(__MODULE__, {:set_ntp_servers, servers})
  end

  @doc """
  Get the list of NTP servers
  """
  @spec ntp_servers() :: [String.t()] | {:error, term()}
  def ntp_servers() do
    GenServer.call(__MODULE__, :ntp_servers)
  end

  @doc """
  Manually restart ntpd
  """
  @spec restart_ntpd() :: :ok | {:error, term()}
  def restart_ntpd() do
    GenServer.call(__MODULE__, :restart_ntpd)
  end

  @impl true
  def init(_args) do
    app_env = Application.get_all_env(:nerves_time)
    ntp_servers = Keyword.get(app_env, :servers, @default_ntp_servers)
    {rtc, rtc_args} = Keyword.get(app_env, :rtc, @default_rtc)

    state =
      %State{servers: ntp_servers, rtc: rtc}
      |> prep_ntpd_start()
      |> schedule_ntpd_start()

    case init_rtc(state, rtc_args) do
      {:ok, state} ->
        _ = adjust_system_time(state)
        {:ok, state}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def terminate(_, state) do
    _ = adjust_system_time(state)
  end

  @impl true
  def handle_call(:synchronized?, _from, state) do
    {:reply, state.synchronized?, state}
  end

  @impl true
  def handle_call(:clean_start?, _from, state) do
    {:reply, state.clean_start?, state}
  end

  @impl true
  def handle_call({:set_ntp_servers, servers}, _from, state) do
    new_state = %{state | servers: servers} |> stop_ntpd() |> schedule_ntpd_start()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:ntp_servers, _from, %State{servers: servers} = state) do
    {:reply, servers, state}
  end

  @impl true
  def handle_call(:restart_ntpd, _from, state) do
    new_state =
      %{state | clean_start?: true}
      |> stop_ntpd()
      |> schedule_ntpd_start()

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_info(:start_ntpd, %State{daemon: nil, servers: servers} = state)
      when servers != [] do
    new_state = start_ntpd(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:start_ntpd, state) do
    # Ignore since ntpd is already running or there are no servers
    {:noreply, state}
  end

  @impl true
  def handle_info({:udp, socket, _, 0, data}, %{socket: socket} = state) do
    report = :erlang.binary_to_term(data)
    handle_ntpd_report(report, state)
  end

  defp prep_ntpd_start(state) do
    path = socket_path()

    # Cleanup the socket file in case of a restart
    clean_start =
      case File.rm(path) do
        {:error, :enoent} ->
          # This is the expected case. There's no stale socket file sitting around
          true

        :ok ->
          _ = Logger.warn("ntpd crash detected. Delaying next start...")
          false
      end

    {:ok, socket} = :gen_udp.open(0, [:local, :binary, {:active, true}, {:ip, {:local, path}}])

    %State{state | socket: socket, clean_start?: clean_start}
  end

  defp schedule_ntpd_start(%State{servers: []} = state) do
    # Don't schedule ntpd to start if no servers configured.
    _ = Logger.warn("Not scheduling ntpd to start since no servers configured")
    state
  end

  defp schedule_ntpd_start(state) do
    delay = ntpd_restart_delay(state)
    Process.send_after(self(), :start_ntpd, delay)
    state
  end

  defp ntpd_restart_delay(%State{clean_start?: false}), do: @ntpd_restart_delay
  defp ntpd_restart_delay(%State{clean_start?: true}), do: @ntpd_clean_start_delay

  defp stop_ntpd(%State{daemon: nil} = state), do: state

  defp stop_ntpd(%State{daemon: pid} = state) do
    GenServer.stop(pid)
    %State{state | daemon: nil, synchronized?: false}
  end

  defp handle_ntpd_report({"stratum", _freq_drift_ppm, _offset, stratum, _poll_interval}, state) do
    state = maybe_update_rtc(state, stratum)

    {:noreply, state}
  end

  defp handle_ntpd_report({"periodic", _freq_drift_ppm, _offset, stratum, _poll_interval}, state) do
    state = maybe_update_rtc(state, stratum)

    {:noreply, state}
  end

  defp handle_ntpd_report({"step", _freq_drift_ppm, _offset, _stratum, _poll_interval}, state) do
    # Ignore
    {:noreply, state}
  end

  defp handle_ntpd_report({"unsync", _freq_drift_ppm, _offset, _stratum, _poll_interval}, state) do
    _ = Logger.error("ntpd reports that it is unsynchronized; restarting")

    # According to the Busybox ntpd docs, if you get an `unsync` notification, then
    # you should restart ntpd to be safe. This is stated to be due to name resolution
    # only being done at initialization.
    new_state =
      state
      |> stop_ntpd()
      |> schedule_ntpd_start()

    {:noreply, new_state}
  end

  defp handle_ntpd_report(report, state) do
    _ = Logger.error("ntpd ignored unexpected report #{inspect(report)}")
    {:noreply, state}
  end

  defp start_ntpd(%State{servers: []} = state), do: state

  defp start_ntpd(%State{servers: servers} = state) do
    ntpd_path = Application.get_env(:nerves_time, :ntpd, @default_ntpd_path)
    ntpd_script_path = Application.app_dir(:nerves_time, ["priv", "ntpd_script"])

    server_args = Enum.flat_map(servers, fn s -> ["-p", s] end)

    # Add "-d" and enable log_output below for more verbose prints from ntpd.
    args = ["-n", "-S", ntpd_script_path | server_args]

    _ = Logger.debug("Starting #{ntpd_path} with: #{inspect(args)}")

    {:ok, pid} =
      MuonTrap.Daemon.start_link(ntpd_path, args,
        env: [{"SOCKET_PATH", socket_path()}],
        stderr_to_stdout: true
        # log_output: :debug
      )

    %{state | daemon: pid, synchronized?: false}
  end

  @spec init_rtc(State.t(), args :: any()) :: {:ok, State.t()} | {:error, reason :: any()}
  def init_rtc(state, args) do
    case state.rtc.init(args) do
      {:ok, rtc_state} ->
        {:ok, %{state | rtc_state: rtc_state}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec maybe_update_rtc(State.t(), integer()) :: State.t()
  defp maybe_update_rtc(state, stratum) when stratum <= 4 do
    case state.rtc.update(state.rtc_state) do
      :ok ->
        %{state | synchronized?: true}

      {:error, _} ->
        %{state | synchronized?: false}
    end
  end

  defp maybe_update_rtc(state, _result), do: %{state | synchronized?: false}

  @spec adjust_system_time(State.t()) :: :ok | :error
  defp adjust_system_time(%State{} = state) do
    now = NaiveDateTime.utc_now()

    with {:ok, %NaiveDateTime{} = time} <- state.rtc.time(state.rtc_state) do
      case NervesTime.SaneTime.derive_time(now, time) do
        ^now ->
          # No change to the current time. This means that we either have a
          # real-time clock that sets the time or the default time that was
          # set is better than any knowledge that we have to say that it's
          # wrong.
          :ok

        new_time ->
          set_system_time(new_time)
      end
    end
  end

  defp set_system_time(%NaiveDateTime{} = time) do
    string_time = time |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()

    case System.cmd("date", ["-u", "-s", string_time]) do
      {_result, 0} ->
        _ = Logger.info("nerves_time initialized clock to #{string_time} UTC")
        :ok

      {message, code} ->
        _ =
          Logger.error(
            "nerves_time failed to set date/time to '#{string_time}': #{code} #{inspect(message)}"
          )

        :error
    end
  end

  defp socket_path() do
    Path.join(System.tmp_dir!(), "nerves_time_comm")
  end
end
