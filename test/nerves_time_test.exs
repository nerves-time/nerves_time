defmodule NervesTimeTest do
  use ExUnit.Case
  doctest Nerves.Time

  @fixtures Path.expand("fixtures", __DIR__)

  setup do
    Application.stop(:nerves_time)
  end

  test "reports that time synchronized when told" do
    Application.put_env(:nerves_time, :ntpd, Path.join(@fixtures, "fake_busybox_ntpd"))
    # Application.start(:nerves_time)
  end
end
