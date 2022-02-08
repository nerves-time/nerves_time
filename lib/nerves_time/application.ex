defmodule NervesTime.Application do
  @moduledoc false
  require Logger
  use Application

  def start(_type, _args) do
    children = [
      NervesTime.SystemTime,
      NervesTime.Ntpd,
      NervesTime.Waiter
    ]

    opts = [strategy: :one_for_one, name: NervesTime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
