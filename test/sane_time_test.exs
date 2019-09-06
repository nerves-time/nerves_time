defmodule SaneTimeTest do
  use ExUnit.Case

  alias NervesTime.SaneTime

  test "dates before build are adjusted" do
    before_build = NaiveDateTime.utc_now() |> Map.put(:year, 2017)
    sane_time = SaneTime.make_sane(before_build)
    assert NaiveDateTime.compare(sane_time, before_build) == :gt
  end

  test "dates way in the future are adjusted" do
    future = NaiveDateTime.utc_now() |> Map.put(:year, 2099)
    sane_time = SaneTime.make_sane(future)
    assert NaiveDateTime.compare(sane_time, future) == :lt
  end
end
