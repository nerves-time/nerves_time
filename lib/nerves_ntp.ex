defmodule Nerves.Ntp do
  use Application
  require Logger

  def start(type, _args) do
    import Supervisor.Spec
    Logger.debug("Starting app in #{type} mode")

    # Define workers and child supervisors to be supervised
    children = [
      worker(Nerves.Ntp.Worker, [])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nerves.Ntp.Worker]
    Supervisor.start_link(children, opts)
  end
end
