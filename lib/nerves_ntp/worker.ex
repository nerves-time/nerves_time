defmodule Nerves.NTP.Worker do
  use GenServer
  alias Nerves.NTP.OutputParser
  require Logger

  @default_ntpd_path "/usr/sbin/ntpd"
  @default_ntp_servers [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  defmodule State do
    @moduledoc false
    defstruct port: nil,
              synchronized: false
  end

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @spec is_synchronized() :: true | false
  def is_synchronized() do
    GenServer.call(__MODULE__, :is_synchronized)
  end

  @spec init(any()) :: {:ok, any()}
  def init(_args) do
    state = %State{port: run_ntpd()}
    {:ok, state}
  end

  def handle_call(:is_synchronized, _from, state) do
    {:reply, state.synchronized, state}
  end

  def handle_info({_, {:exit_status, code}}, state) do
    Logger.error("ntpd exited with code: #{code}!")
    {:stop, :ntpd_died, state}
  end

  def handle_info({_, {:data, {:eol, message}}}, state) do
    message
    |> OutputParser.parse()
    |> handle_ntpd(state)
  end

  defp run_ntpd() do
    ntpd_path = Application.get_env(:nerves_ntp, :ntpd, @default_ntpd_path)
    servers = Application.get_env(:nerves_ntp, :servers, @default_ntp_servers)
    set_time = Application.get_env(:nerves_ntp, :set_time, true)
    ntpd_script_path = Application.app_dir(:nerves_ntp, "priv/ntpd_script")

    args =
      [ntpd_path, "-n", "-d", "-S", ntpd_script_path] ++
        server_args(servers) ++ set_time_args(set_time)

    Logger.debug("Running ntp as: #{inspect(args)}")

    # Call ntpd using muontrap. Muontrap will kill ntpd if this GenServer
    # crashes.

    Port.open({:spawn_executable, MuonTrap.muontrap_path()}, [
      {:args, ["--" | args]},
      :exit_status,
      :use_stdio,
      :binary,
      {:line, 2048},
      :stderr_to_stdout
    ])
  end

  defp server_args(servers) do
    Enum.flat_map(servers, fn s -> ["-p", s] end)
  end

  defp set_time_args(true), do: []
  defp set_time_args(false), do: ["-w"]

  defp handle_ntpd({report, result}, state) when report in [:stratum, :periodic] do
    synchronized = maybe_update_clock(result)
    {:noreply, %{state | synchronized: synchronized}}
  end

  defp handle_ntpd({:unsync, _result}, state) do
    Logger.error("ntpd reports that it is unsynchronized; relaunching")

    # According to the Busybox ntpd docs, if you get an `unsync` notification, then
    # you should restart ntpd to be safe. This is stated to be due to name resolution
    # only being done at initialization.
    Port.close(state.port)

    new_state = %{state | port: run_ntpd(), synchronized: false}
    {:noreply, new_state}
  end

  defp handle_ntpd({:step, result}, state) do
    Logger.debug("ntpd stepped the clock: #{inspect(result)}")
    {:noreply, state}
  end

  defp handle_ntpd(_message, state) do
    # Logger.debug("ntpd got: #{inspect message}")
    {:noreply, state}
  end

  defp maybe_update_clock(%{stratum: stratum})
       when stratum <= 4 do
    # Update the time assuming that we're getting time from a decent clock.
    Nerves.NTP.FileTime.update()
    true
  end

  defp maybe_update_clock(_result), do: false

  # Future: Need to attach a RTC
  # Note: the Busybox ntpd source waits for poll_interval to be >=128. This
  #       actually takes a little while.
  # defp maybe_update_hwclock()
end
