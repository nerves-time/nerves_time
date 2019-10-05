# Changelog

## v0.3.1

* Bug fixes
  * Move ntpd's prints to the log. The previous prints to the console were quite
    annoying to say the least.
  * Remove the build timestamp so that `nerves_time` builds are reproducible.
    This is important for users that want to recreate firmware images with as
    few differences as possible. The build timestamp had restricted the earliest
    allowed time. The earliest time is now hardcoded, but can be overridden by
    application config (same with the latest possible time.)

## v0.3.0

IMPORTANT: This release moves `Nerves.Time` to the `NervesTime` namespace. If
you are using the API, you will need to rename every instance of `Nerves.Time`
in your code to `NervesTime`.

* Bug fixes
  * `ntpd` crash detection and restart have been simplified by using
    `MuonTrap.Daemon`. This should fix an issue that was seen with `ntpd` not
    getting restarted after it crashed.
  * `NervesTime.synchronized?/0` would return synchronized when changing NTP
    servers and right after restarting `ntpd`. It will return `false` now and
    switch to `true` when time really has been synchronized.

* Improvements
  * Simplified ntpd reporting code. No more regular expressions. Reports are
    sent via a Unix Domain socket and encoded as Erlang terms. This deleted a
    lot of string parsing code that felt brittle.
  * Added a restart delay on unclean `ntpd` restarts to prevent pegging public
    NTP servers. The delay is currently a minute since `ntpd` crashes are not
    well-understood. Luckily, this seems like a rare event.
  * Added more tests to cover NTP use

## v0.2.1

* Improvements
  * Move C build products under `_build`. This lets you switch targets with out
    cleaning builds in between.

## v0.2.0

* Added support for configuring NTP servers at runtime. Thanks to @ConnorRigby
  for sending a PR for this
* Added `Nerves.Time.restart_ntpd/0` for users who know external information
  about good times to bounce the NTP daemon so that it syncs more quickly
* Fixed naming of `is_synchronized/0` to be `synchronized?/0`. Thanks to
  @brodeuralexis for catching my slip.

## v0.1.0

Initial release
