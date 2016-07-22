# NervesNtp

NervesNtp is simple OTP application which synchronizes time using busybox `ntpd` command. Primary use is for [Nerves](http://nerves-project.org) embedded devices without RTC.

There are two configuration options:

```elixir
# config/config.exs
use Mix.Config

# ntpd binary to use
config :nerves_ntp, :ntpd, "/usr/sbin/ntpd"
 
# servers to sync time from
config :nerves_ntp, :servers, [
    "0.pool.ntp.org",
    "1.pool.ntp.org", 
    "2.pool.ntp.org", 
    "3.pool.ntp.org"
  ]
```

## Installation

The package can be installed as:

  1. Add `nerves_ntp` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:nerves_ntp, "~> 0.1.0"}]
    end
    ```

  2. Ensure `nerves_ntp` is started before your application:

    ```elixir
    def application do
      [applications: [:nerves_ntp]]
    end
    ```

