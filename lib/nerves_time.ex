defmodule Nerves.Time do
  @moduledoc """

  """

  @doc """
  Check whether NTP is synchronized with the configured NTP servers.

  It's possible that the time is already set correctly when this
  returns false. Nerves.Time decides that NTP is synchronized when
  ntpd sends a notification that the device's clock stratum is 4 or less.
  """
  defdelegate is_synchronized, to: Nerves.Time.Ntpd
end
