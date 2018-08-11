defmodule Nerves.NTP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Nerves.NTP.Worker, []}
    ]

    opts = [strategy: :one_for_one, name: Nerves.NTP.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
