# SPDX-FileCopyrightText: 2016 Marcin Operacz
# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Eric Rauer
# SPDX-FileCopyrightText: 2022 Benjamin Milde
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime do
  @moduledoc """
  Keep time in sync on Nerves devices

  `NervesTime` keeps the system clock on [Nerves](http://nerves-project.org)
  devices in sync when connected to the network and close to in sync when
  disconnected. It's especially useful for devices lacking a [Battery-backed
  real-time clock](https://en.wikipedia.org/wiki/Real-time_clock) and will
  advance the clock at startup to a reasonable guess.

  Nearly all configuration is via the application config (`config.exs`). The
  following keys are available:

  * `:servers` - a list of NTP servers for time synchronization. Specifying an
    empty list turns off NTP
  * `:time_sources` - an ordered list of supplemental time sources to use when
    NTP has not yet synchronized. Each entry is either a bare module atom or a
    `{module, opts}` tuple, where the module implements the
    `NervesTime.TimeSource` behaviour. Sources are tried in order; the first to
    return a valid time sets the clock. Defaults to `[NervesTime.HTTP]`, which
    queries `http://whenwhere.nerves-project.org/` by default. Set to `[]` to
    disable all supplemental sources.
  * `:time_file` - a file path for tracking the time. It allows the system to
    start with a reasonable time quickly on boot and before the Internet is
    available for NTP to work.
  * `:earliest_time` - times before this are considered invalid and adjusted
  * `:latest_time` - times after this are considered invalid and adjusted
  * `:ntpd` - the absolute path to the Busybox `ntpd`. This only needs to be
    set if your system does not provide `ntpd` in the `$PATH`.
  * `:await_initialization_timeout` - Timeout to await a successful system time
    initialization on startup before continuing asynchronously. Set in milliseconds.
    Defaults to `0`.
  """

  @doc """
  Set the system time
  """
  @spec set_system_time(NaiveDateTime.t()) :: :ok | :error
  defdelegate set_system_time(time), to: NervesTime.SystemTime, as: :set_time

  @doc """
  Check whether the system clock has been synchronized by any configured time source

  Returns `true` if either NTP or a supplemental time source (e.g.
  `NervesTime.HTTP`) has successfully set the clock.

  For NTP specifically, synchronization is declared when `ntpd` reports a clock
  stratum of 4 or less. Clock adjustments from NTP may occur before this point.

  Once synchronized, this returns `true` until the `nerves_time` application is
  restarted.
  """
  @spec synchronized?() :: boolean()
  defdelegate synchronized?, to: NervesTime.Ntpd

  @doc """
  Set the list of NTP servers

  Use this function to replace the list of NTP servers that are queried for
  time. It is also possible to set this list in your `config.exs` by doing
  something like the following:

  ```elixir
  config :nerves_time, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]
  ```

  `NervesTime` uses [NTP Pool](https://www.ntppool.org/en/) by default. To
  disable this and configure servers solely at runtime, specify an empty list
  in `config.exs`:

  ```elixir
  config :nerves_time, :servers, []
  ```
  """
  @spec set_ntp_servers([String.t()]) :: :ok
  defdelegate set_ntp_servers(servers), to: NervesTime.Ntpd

  @doc """
  Return the current NTP servers
  """
  @spec ntp_servers() :: [String.t()] | {:error, term()}
  defdelegate ntp_servers(), to: NervesTime.Ntpd

  @doc """
  Manually restart the NTP daemon

  This is normally not necessary since `NervesTime` handles restarting it
  automatically. An example of a reason to call this function is if you know
  when the Internet becomes available. For this case, calling `restart_ntp`
  will cancel `ntpd`'s internal timeouts and cause it to immediately send time
  requests. If using NTP Pool, be sure not to violate its terms of service by
  calling this function too frequently.
  """
  @spec restart_ntpd() :: :ok | {:error, term()}
  defdelegate restart_ntpd(), to: NervesTime.Ntpd
end
