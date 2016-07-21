defmodule Nerves.Ntp.Worker do
  use GenServer
  require Logger

  @ntpd Application.get_env(:nerves_ntp, :ntpd, "/usr/sbin/ntpd")
  @servers Application.get_env(:nerves_ntp, :servers, ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org"])


  def start_link do
    Logger.debug "Starting Worker"
    GenServer.start_link(__MODULE__, :ok)
  end

  def init(args) do
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
    # {:ok, {}}
  end

  # def terminate(reason, state) do
  #   case Port.info(state) do
  #      nil -> nil
  #      a -> Logger.error(a)
  #   end    
  # end

  def handle_info({_, {:exit_status, code}}, state) do
    Logger.debug "ntpd exited with code: #{code}"
    with 1 <- code do
      # ntp exited so we will try to restart it after 2 sek
      # Port.close(state) // not required... as port is already closed
      Process.sleep(2_000)
      {:stop, :ntp_die, nil}
    else
      _ ->
        {:noreply, state}
    end
  end

  def handle_info({_, {:data, {:eol, data}}}, port) do
    Logger.debug "Received data from port #{data}"
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

  def handle_call(request, _from, state) do
    Logger.debug "#{inspect state}"
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
    regex = ~r/from (?<server>(?:[0-9]{1,3}\.){3}[0-9]{1,3}).*delay:(?<delay>\d\.\d{6})/
    captures = Regex.named_captures(regex, data)
    parse_ntp_reply captures
  end

  def parse_ntp_output(data) do
    Logger.debug data
  end

  def parse_ntp_reply(%{"delay" => delay, "server" => server}) do
    Logger.debug("Got reply form server #{server}, time offset is: #{delay}")
  end

  # def parse_ntp_output(data) when is_binary(data) do
  #   # Logger.error inspect(data)
  #   data
  #     |> :binary.split(<<"\n">>)
  #     # |> IO.puts
  #     # |> Logger.error
  #     |> Enum.map(&(parse_ntp_output(&1)))
  # end


end
