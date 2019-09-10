defmodule NervesTime.RTC do
  require Logger
  use GenServer
  use Bitwise

  def update() do
    GenServer.call(__MODULE__, {:set_time, NaiveDateTime.utc_now()})
  end

  def time() do
    GenServer.call(__MODULE__, :get_time)
  end

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp set_time(%NaiveDateTime{} = time) do
    string_time = time |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_string()

    case System.cmd("date", ["-u", "-s", string_time]) do
      {_result, 0} ->
        _ = Logger.info("nerves_time initialized clock to #{string_time} UTC")
        :ok

      {message, code} ->
        _ =
          Logger.error(
            "nerves_time failed to set date/time to '#{string_time}': #{code} #{inspect(message)}"
          )

        :error
    end
  end

  def init(_args) do
    {:ok, i2c} = Circuits.I2C.open("i2c-1")
    send(self(), :adjust_clock)
    {:ok, %{i2c: i2c}}
  end

  def terminate(_, state) do
    _ = do_write(state.i2c, NaiveDateTime.utc_now())
  end

  def handle_info(:adjust_clock, state) do
    rtc_time = do_read(state.i2c)
    now = NaiveDateTime.utc_now()

    case NervesTime.SaneTime.derive_time(now, rtc_time) do
      ^now ->
        # No change to the current time. This means that we either have a
        # real-time clock that sets the time or the default time that was
        # set is better than any knowledge that we have to say that it's
        # wrong.
        :ok

      new_time ->
        set_time(new_time)
    end

    {:noreply, state}
  end

  def handle_call({:set_time, %NaiveDateTime{} = time}, _from, state) do
    {:reply, do_write(state.i2c, time), state}
  end

  def handle_call(:get_time, _from, state) do
    {:reply, do_read(state.i2c), state}
  end

  defp do_write(i2c, time) do
    day_of_week = Calendar.ISO.day_of_week(time.year, time.month, time.day)

    payload = <<
      0x02,
      to_bcd(time.second),
      to_bcd(time.minute),
      to_bcd(time.hour),
      to_bcd(time.month),
      to_bcd(day_of_week),
      to_bcd(time.month),
      to_bcd(time.year - 2000)
    >>

    Circuits.I2C.write(i2c, 81, payload)
  end

  defp do_read(i2c) do
    {:ok,
     <<
       second::integer-size(8),
       minute::integer-size(8),
       hour::integer-size(8),
       day_of_month::integer-size(8),
       _day_of_week::integer-size(8),
       month::integer-size(8),
       year::integer-size(8)
     >>} = Circuits.I2C.write_read(i2c, 81, <<0x02>>, 7)

    second = second &&& 0b01111111
    minute = minute &&& 0b01111111
    hour = hour &&& 0b00111111
    day_of_month = day_of_month &&& 0b00111111
    # day_of_week = day_of_week &&& 0b00000111

    # first bit here is century bit. 
    month = month &&& 0b00011111

    %NaiveDateTime{
      calendar: Calendar.ISO,
      day: to_dec(day_of_month),
      hour: to_dec(hour),
      minute: to_dec(minute),
      month: to_dec(month),
      second: to_dec(second),
      year: to_dec(year) + 2000
    }
  end

  defp to_dec(bcd) do
    <<digit_1::integer-size(4), digit_2::integer-size(4)>> = <<bcd::integer-size(8)>>
    digit_1 * 10 + digit_2
  end

  def to_bcd(number) do
    div(number, 10) * 16 + rem(number, 10)
  end
end
