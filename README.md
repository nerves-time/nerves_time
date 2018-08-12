# nerves_time

[![CircleCI](https://circleci.com/gh/fhunleth/nerves_time.svg?style=svg)](https://circleci.com/gh/fhunleth/nerves_time)
[![Hex version](https://img.shields.io/hexpm/v/nerves_time.svg "Hex version")](https://hex.pm/packages/nerves_time)

`Nerves.Time` keeps the system clock on [Nerves](http://nerves-project.org)
devices in sync when connected to the network and close to in sync when
disconnected. It's especially useful for devices lacking a [Battery-backed
real-time clock](https://en.wikipedia.org/wiki/Real-time_clock) and will advance
the clock at startup to a reasonable guess.

## Installation

First add `nerves_time` to your project's dependencies:

```elixir
def deps do
  [
    {:nerves_time, "~> 0.1.0"}
  ]
end
```

If you're using one of the official Nerves Systems, then this is all that's
needed. `nerves_time` requires Busybox's `ntpd` and `date` applets to be
enabled. If you haven't explicitly disabled the, they're probably enabled.

## Configuration

`nerves_time` uses [ntp.pool.org](https://www.ntppool.org/en/) for time
synchronization. Please see their [terms of
use](https://www.ntppool.org/tos.html) before tweaking `nerves_time`.
Alternative NTP servers can be specified using the `config.exs`:

```elixir
# config/config.exs

config :nerves_time, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]
```

## Algorithm

Here's the basic idea behind `nerves_time`:

* If the clock hasn't been set or is invalid, set it to the time that
  `nerves_time` was compiled.
* Check for `~/.nerves_time`. If it exists, advance the clock to it's last
  modification time.
* Run Busybox `ntpd` to synchronize time using the [NTP
  protocol](https://en.wikipedia.org/wiki/Network_Time_Protocol).
* Update `~/.nerves_time` periodically and on graceful power downs. This is
  currently only done at around 11 minute intervals to avoid needless exercising
  of Flash-based memory.

To check the NTP synchronization status, call `Nerves.Time.synchronized?/0`.

## Credits and license

This project started as a fork of
[nerves_ntp](https://hex.pm/packages/nerves_ntp) by Marcin Operacz and Wojciech
Mandrysz. It has quite a few changes from since when they worked on the project,
but some of their code still exists. Both their project and this one are covered
by the [Apache-2.0 license](https://opensource.org/licenses/Apache-2.0).
