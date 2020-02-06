defmodule NervesTime.Application do
  @moduledoc false
  require Logger
  use Application

  def start(_type, _args) do
    children = [
      {NervesTime.Ntpd, []}
    ]

    opts = [strategy: :one_for_one, name: NervesTime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
