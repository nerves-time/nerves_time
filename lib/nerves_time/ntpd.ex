defmodule Nerves.Time.Ntpd do
  use GenServer
  alias Nerves.Time.{NtpdParser, FileTime}
  require Logger

  @moduledoc false

  @default_ntpd_path "/usr/sbin/ntpd"
  @default_ntp_servers [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  defmodule State do
    @moduledoc false
    @type t() :: %__MODULE__{port: nil | port(), synchronized: boolean()}
    defstruct port: nil,
              synchronized: false
  end

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec synchronized?() :: boolean()
  def synchronized?() do
    GenServer.call(__MODULE__, :synchronized?)
  end

  @spec set_ntp_servers([String.t()]) :: :ok
  def set_ntp_servers(servers) when is_list(servers) do
    GenServer.call(__MODULE__, {:set_ntp_servers, servers})
  end

  @spec ntp_servers() :: [String.t()] | {:error, term()}
  def ntp_servers() do
    GenServer.call(__MODULE__, :ntp_servers)
  end

  @spec restart_ntpd() :: :ok | {:error, term()}
  def restart_ntpd() do
    GenServer.call(__MODULE__, :restart_ntpd)
  end

  @spec init(any()) :: {:ok, State.t()}
  def init(_args) do
    {:ok, do_restart_ntpd(%State{})}
  end

  def handle_call(:synchronized?, _from, state) do
    {:reply, state.synchronized, state}
  end

  def handle_call({:set_ntp_servers, servers}, _from, state) do
    Application.put_env(:nerves_time, :servers, servers)
    new_state = do_restart_ntpd(state)
    {:reply, :ok, new_state}
  end

  def handle_call(:restart_ntpd, _from, state) do
    new_state = do_restart_ntpd(state)

    result =
      case new_state.port do
        nil -> {:error, "No NTP servers defined"}
        _ -> :ok
      end

    {:reply, result, new_state}
  end

  def handle_call(:ntp_servers, _from, state) do
    {:reply, get_ntp_servers(), state}
  end

  def handle_info({_, {:exit_status, code}}, state) do
    Logger.error("ntpd exited with code: #{code}!")
    {:stop, :ntpd_died, state}
  end

  def handle_info({_, {:data, {:eol, message}}}, state) do
    message
    |> NtpdParser.parse()
    |> handle_ntpd(state)
  end

  defp get_ntp_servers() do
    Application.get_env(:nerves_time, :servers, @default_ntp_servers)
  end

  defp server_args(servers) do
    Enum.flat_map(servers, fn s -> ["-p", s] end)
  end

  defp handle_ntpd({report, result}, state) when report in [:stratum, :periodic] do
    synchronized = maybe_update_clock(result)

    if synchronized != state.synchronized do
      Logger.info("ntpd synchronization changed (now #{synchronized}): #{inspect(result)}")
    end

    {:noreply, %{state | synchronized: synchronized}}
  end

  defp handle_ntpd({:unsync, _result}, state) do
    Logger.error("ntpd reports that it is unsynchronized; restarting")

    # According to the Busybox ntpd docs, if you get an `unsync` notification, then
    # you should restart ntpd to be safe. This is stated to be due to name resolution
    # only being done at initialization.
    new_state = do_restart_ntpd(state)

    {:noreply, new_state}
  end

  defp handle_ntpd({:step, result}, state) do
    Logger.debug("ntpd stepped the clock: #{inspect(result)}")
    {:noreply, state}
  end

  defp handle_ntpd(_message, state) do
    # Logger.debug("ntpd got: #{inspect _message}")
    {:noreply, state}
  end

  defp do_restart_ntpd(state) do
    if is_port(state.port) do
      Port.close(state.port)
    end

    ntpd = maybe_start_ntpd(get_ntp_servers())

    %{state | port: ntpd, synchronized: false}
  end

  defp maybe_start_ntpd([]) do
    Logger.debug("Not starting ntpd since no NTP servers.")
    nil
  end

  defp maybe_start_ntpd(servers) do
    ntpd_path = Application.get_env(:nerves_time, :ntpd, @default_ntpd_path)
    ntpd_script_path = Application.app_dir(:nerves_time, "priv/ntpd_script")

    args = [ntpd_path, "-n", "-d", "-S", ntpd_script_path] ++ server_args(servers)

    Logger.debug("Starting ntpd as: #{inspect(args)}")

    # Call ntpd using muontrap. Muontrap will kill ntpd if this GenServer
    # crashes.
    Port.open({:spawn_executable, MuonTrap.muontrap_path() |> to_charlist()}, [
      {:args, ["--" | args]},
      :exit_status,
      :use_stdio,
      :binary,
      {:line, 2048},
      :stderr_to_stdout
    ])
  end

  defp maybe_update_clock(%{stratum: stratum})
       when stratum <= 4 do
    # Update the time assuming that we're getting time from a decent clock.
    FileTime.update()
    true
  end

  defp maybe_update_clock(_result), do: false

  # Future: Need to attach a RTC
  # Note: the Busybox ntpd source waits for poll_interval to be >=128. This
  #       actually takes a little while.
  # defp maybe_update_hwclock()
end
