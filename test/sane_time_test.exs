# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule SaneTimeTest do
  use ExUnit.Case

  alias NervesTime.SaneTime

  test "dates within range are not adjusted" do
    time = ~N[2027-01-01 00:00:00]
    sane_time = SaneTime.make_sane(time)
    assert time == sane_time
  end

  test "dates before build are adjusted forward" do
    before_build = ~N[2019-01-01 00:00:00]
    sane_time = SaneTime.make_sane(before_build)
    assert NaiveDateTime.compare(sane_time, before_build) == :gt
  end

  test "future dates are adjusted backwards" do
    future = ~N[2099-01-01 00:00:00]
    sane_time = SaneTime.make_sane(future)
    assert NaiveDateTime.compare(sane_time, future) == :lt
  end

  test "possible to override the earliest date" do
    distant_past = ~N[1975-01-01 00:00:00]
    Application.put_env(:nerves_time, :earliest_time, distant_past)
    epoch = ~N[1970-01-01 00:00:00]
    sane_time = SaneTime.make_sane(epoch)
    assert sane_time == distant_past
    Application.delete_env(:nerves_time, :earliest_time)
  end

  test "possible to override the latest date" do
    distant_past = ~N[1975-01-01 00:00:00]
    less_distant_past = ~N[1979-01-01 00:00:00]

    Application.put_env(:nerves_time, :earliest_time, distant_past)
    Application.put_env(:nerves_time, :latest_time, less_distant_past)

    sane_time = SaneTime.make_sane(NaiveDateTime.utc_now())
    assert sane_time == distant_past

    Application.delete_env(:nerves_time, :earliest_time)
    Application.delete_env(:nerves_time, :latest_time)
  end
end
