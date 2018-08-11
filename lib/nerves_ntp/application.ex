defmodule Nerves.NTP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Nerves.NTP.Worker, []}
    ]

    # Sanity check and adjust the clock
    adjust_clock()

    opts = [strategy: :one_for_one, name: Nerves.NTP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def stop(_state) do
    # Update the file that keeps track of the time one last time.
    Nerves.NTP.FileTime.update()
  end

  defp adjust_clock() do
    file_time = Nerves.NTP.FileTime.time()
    now = NaiveDateTime.utc_now()

    case Nerves.NTP.SaneTime.derive_time(now, file_time) do
      ^now ->
        # No change to the current time. This means that we either have a
        # real-time clock that sets the time or the default time that was
        # set is better than any knowledge that we have to say that it's
        # wrong.
        :ok

      new_time ->
        IO.puts("I want to change the time to #{inspect(new_time)}!")
    end
  end
end
