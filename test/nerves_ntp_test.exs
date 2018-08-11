defmodule NervesNTPTest do
  use ExUnit.Case
  doctest Nerves.NTP

  @fixtures Path.expand("fixtures", __DIR__)

  setup do
    Application.stop(:nerves_ntp)
  end

  test "reports that time synchronized when told" do
    Application.put_env(:nerves_ntp, :ntpd, Path.join(@fixtures, "fake_busybox_ntpd"))
    # Application.start(:nerves_ntp)
  end
end
