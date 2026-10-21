# SPDX-FileCopyrightText: 2026 Bryan Leong
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.SystemTimeTest do
  use ExUnit.Case

  alias NervesTime.SystemTime

  @moduletag :capture_log

  defmodule FakeRTC do
    @behaviour NervesTime.RealTimeClock

    @impl NervesTime.RealTimeClock
    def init(time), do: {:ok, time}

    @impl NervesTime.RealTimeClock
    def terminate(_time), do: :ok

    @impl NervesTime.RealTimeClock
    def get_time(time), do: {:ok, time, time}

    @impl NervesTime.RealTimeClock
    def set_time(_time, new_time) do
      send(self(), {:set_time, new_time})
      new_time
    end
  end

  defp start_with_rtc_time(time) do
    {:noreply, state} =
      SystemTime.handle_continue(:continue, %SystemTime.State{rtc_spec: {FakeRTC, time}})

    state
  end

  test "an RTC reporting an invalid time is set to the system time" do
    invalid = %NaiveDateTime{year: 2030, month: 0, day: 12, hour: 4, minute: 34, second: 41}

    state = start_with_rtc_time(invalid)

    assert_received {:set_time, written}
    assert abs(NaiveDateTime.diff(written, NaiveDateTime.utc_now())) < 60
    assert state.rtc_state == written
  end

  test "an RTC reporting a valid time is not set" do
    rtc_time = NaiveDateTime.add(NaiveDateTime.utc_now(), -60)

    state = start_with_rtc_time(rtc_time)

    refute_received {:set_time, _}
    assert state.rtc_state == rtc_time
  end
end
