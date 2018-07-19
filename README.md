# nerves_ntp

Synchronize the time on your [Nerves](http://nerves-project.org) device using
[NTP](https://en.wikipedia.org/wiki/Network_Time_Protocol).

## Usage

First add `nerves_ntp` to your project's dependencies:

```elixir
def deps do
  [{:nerves_ntp, "~> 0.1.0"}]
end
```

The next step is to update the configuration if the defaults don't work. If you
are unsure, you probably can skip this step for now. The following code shows
the defaults:

```elixir
# config/config.exs
use Mix.Config

# Specify the ntpd binary. All Nerves systems include Busybox's ntpd by default
config :nerves_ntp, :ntpd, "/usr/sbin/ntpd"

# Specify time servers. See https://www.ntppool.org/en/use.html if you use this
# in production
config :nerves_ntp, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]
```
