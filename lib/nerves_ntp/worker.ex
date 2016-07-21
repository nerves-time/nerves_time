defmodule Nerves.Ntp.Worker do
  use GenServer
  require Logger

  @ntpd Application.get_env(:nerves_ntp, :ntpd, "/usr/sbin/ntpd")
  @servers Application.get_env(:nerves_ntp, :servers, ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org"])


  def start_link do
    Logger.debug "Starting Worker"
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(_args) do
    Logger.debug "Binary to use: #{@ntpd}"
    Logger.debug "Configured servers are: #{inspect @servers}"
    Logger.debug ~s(Command to run: "#{ntp_cmd}")    
    ntpd = Port.open({:spawn, ntp_cmd}, [
        :exit_status,
        :use_stdio,
        :binary,
        {:line, 2048},
        :stderr_to_stdout
      ])
    {:ok, ntpd}
  end

  def handle_info({_, {:exit_status, code}}, _state) do
    Logger.debug "ntpd exited with code: #{code}"
    # ntp exited so we will try to restart it after 10 sek
    # Port.close(state) // not required... as port is already closed
    Process.sleep(10_000)
    {:stop, :shutdown, nil}
  end

  def handle_info({_, {:data, {:eol, data}}}, port) do
    # Logger.debug "Received data from port #{data}" // turned off
    parse_ntp_output data
    {:noreply, port}
  end

  def handle_info(msg, state) do
    Logger.debug "#{inspect msg}"
    Logger.debug "#{inspect state}"
    {:noreply, state}
  end


  def handle_call(:start, _from, state) do
    Logger.debug "start"

    {:reply, :ok, state}
  end 


  defp ntp_cmd do
    "#{@ntpd} -n -d"
      |> add_servers
  end

  def add_servers(cmd) do
    add_servers(cmd, @servers)
  end

  def add_servers(cmd, [h | t]) do
    add_servers cmd <> " -p #{h}", t
  end

  def add_servers(cmd, []) do
    cmd
  end

  
  def parse_ntp_output("ntpd: reply " <> data) do
    regex = ~r/from (?<server>(?:[0-9]{1,3}\.){3}[0-9]{1,3}).*offset:[+-](?<offset>\d+\.\d{6})/
    captures = Regex.named_captures(regex, data)
    parse_ntp_reply captures
  end

  def parse_ntp_output(_data) do
    # Logger.debug data
    :ok
  end

  def parse_ntp_reply(%{"offset" => offset, "server" => server}) do
    Logger.debug("Got reply form server #{server}, time offset is: #{offset}")
  end


end
