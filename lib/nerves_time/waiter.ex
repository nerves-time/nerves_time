defmodule NervesTime.Waiter do
  @moduledoc """
  Waits for `NervesTime.SystemTime` to successfully set a sane real time.

  By default that time is fetched completely async, but this waiter can be
  configured using `config :nerves_time, wait_for_rtc_timeout: timeout` to
  block startup for the configured duration. If the timeout elapses there's
  still no guarantee for a sane real time being set. Setting the timeout
  to `:infinity` will however block until that happens.
  """
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_) do
    timeout = Application.fetch_env!(:nerves_time, :wait_for_rtc_timeout)

    with :timeout <- NervesTime.SystemTime.await_initialization(timeout),
         t when t > 0 <- timeout do
      Logger.warn("Timeout expired when waiting for system time adjustment")
    end

    :ignore
  end
end
