defmodule NervesTimeTest do
  use ExUnit.Case
  doctest Nerves.Time

  @fixtures Path.expand("fixtures", __DIR__)

  setup do
    Application.stop(:nerves_time)
  end

  test "reports that time synchronized when told" do
    Application.put_env(:nerves_time, :ntpd, Path.join(@fixtures, "fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)

    # The fake_busybox_ntpd should have reported synchronization by this time.
    assert Nerves.Time.synchronized?()
  end

  test "reports that time not synchronized when net is down" do
    Application.put_env(:nerves_time, :ntpd, Path.join(@fixtures, "fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    Process.sleep(100)

    refute Nerves.Time.synchronized?()
  end
end
