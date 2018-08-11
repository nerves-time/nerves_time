defmodule Nerves.NTP.Worker do
  use GenServer
  alias Nerves.NTP.OutputParser
  require Logger

  @ntpd Application.get_env(:nerves_ntp, :ntpd, "/usr/sbin/ntpd")
  @servers Application.get_env(:nerves_ntp, :servers, [
             "0.pool.ntp.org",
             "1.pool.ntp.org",
             "2.pool.ntp.org",
             "3.pool.ntp.org"
           ])

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_args) do
    Logger.debug("Starting Worker")
    GenServer.start_link(__MODULE__, :ok)
  end

  @spec init(any()) :: {:ok, any()}
  def init(_args) do
    Logger.debug("Binary to use: #{@ntpd}")
    Logger.debug("Configured servers are: #{inspect(@servers)}")
    Logger.debug(~s(Command to run: "#{ntp_cmd()}"))

    ntpd = nil
    # ntpd =
    #   Port.open({:spawn, ntp_cmd()}, [
    #     :exit_status,
    #     :use_stdio,
    #     :binary,
    #     {:line, 2048},
    #     :stderr_to_stdout
    #   ])

    {:ok, ntpd}
  end

  def handle_info({_, {:exit_status, code}}, _state) do
    Logger.debug("ntpd exited with code: #{code}")
    # ntp exited so we will try to restart it after 10 sek
    # Port.close(state) // not required... as port is already closed
    pause_and_die()
  end

  def handle_info({_, {:data, {:eol, message}}}, port) do
    # Logger.debug "Received data from port #{message}"
    result = OutputParser.parse(message)
    IO.inspect(result)

    {:noreply, port}
  end

  def handle_info(msg, state) do
    Logger.debug("#{inspect(msg)}")
    Logger.debug("#{inspect(state)}")
    {:noreply, state}
  end

  def handle_call(:start, _from, state) do
    Logger.debug("start")

    {:reply, :ok, state}
  end

  defp pause_and_die do
    Process.sleep(10_000)
    {:stop, :shutdown, nil}
  end

  defp ntp_cmd do
    "#{@ntpd} -n -d"
    |> add_servers
  end

  defp add_servers(cmd), do: add_servers(cmd, @servers)
  defp add_servers(cmd, [h | t]), do: add_servers(cmd <> " -p #{h}", t)
  defp add_servers(cmd, []), do: cmd
end
