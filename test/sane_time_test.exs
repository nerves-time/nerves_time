defmodule SaneTimeTest do
  use ExUnit.Case

  alias Nerves.NTP.SaneTime

  test "dates before build are adjusted" do
    before_build = DateTime.utc_now() |> Map.put(:year, 2017)
    sane_time = SaneTime.make_sane(before_build)
    assert DateTime.compare(sane_time, before_build) == :gt
  end

  test "dates way in the future are adjusted" do
    future = DateTime.utc_now() |> Map.put(:year, 2099)
    sane_time = SaneTime.make_sane(future)
    assert DateTime.compare(sane_time, future) == :lt
  end
end
