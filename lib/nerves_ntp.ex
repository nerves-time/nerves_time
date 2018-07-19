defmodule Nerves.NTP do
  use Application
  require Logger

  def start(type, _args) do
    import Supervisor.Spec
    Logger.debug("Starting app in #{type} mode")

    children = [
      worker(Nerves.NTP.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Nerves.NTP.Worker]
    Supervisor.start_link(children, opts)
  end
end
