# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.RealTimeClock.BCDTest do
  use ExUnit.Case
  alias NervesTime.RealTimeClock.BCD

  test "all values convert" do
    for tens <- 0..9, ones <- 0..9 do
      number = tens * 10 + ones
      bcd = tens * 16 + ones

      assert BCD.from_integer(number) == bcd
      assert BCD.to_integer(bcd) == number
    end
  end
end
