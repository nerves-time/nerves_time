defmodule Nerves.Ntp do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec
    Logger.debug "Starting app in #{_type} mode"
    # ntp_server = Application.get_env(:ntp, :wlan0)
    # Nerves.InterimWiFi.setup "wlan0", wifi_opts

    # Define workers and child supervisors to be supervised
    children = [
      worker(Nerves.Ntp.Worker, [])
    ]    
    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nerves.Ntp.Worker]
    Supervisor.start_link(children, opts)
  end

  # def start do
  #   GenServer.call(Nerves.Ntp.Worker, :start)
  # end

end
