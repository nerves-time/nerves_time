# Changelog

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
