defmodule Nerves.Time do
  @moduledoc """
  `Nerves.Time` keeps the system clock on [Nerves](http://nerves-project.org)
  devices in sync when connected to the network and close to in sync when
  disconnected. It's especially useful for devices lacking a [Battery-backed
  real-time clock](https://en.wikipedia.org/wiki/Real-time_clock) and will advance
  the clock at startup to a reasonable guess.
  """

  @doc """
  Check whether NTP is synchronized with the configured NTP servers.

  It's possible that the time is already set correctly when this
  returns false. Nerves.Time decides that NTP is synchronized when
  ntpd sends a notification that the device's clock stratum is 4 or less.
  """
  defdelegate is_synchronized, to: Nerves.Time.Ntpd

  @doc """
  Can be used to configure NTP server pool at runtime.
  """
  def configure_servers(servers) when is_list(servers) do
    Application.put_env(:nerves_time, :servers, servers)
  end
end
