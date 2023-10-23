defmodule NervesTime.BatteryBackedTime do
  @behaviour NervesTime.RealTimeClock

  @moduledoc """
  An implementation that always returns the system time.

  This should be used only if you know the device has a battery backed realtime clock.
  When `NervesTime.SystemTime` does a sanity check, the system time will be the same
  as the rtc time. This can cause the system to report a sucessful synchronization, before
  ntp synchronization has occured.
  """

  @doc false
  @impl NervesTime.RealTimeClock
  @spec init(args :: any()) :: {:ok, any()}
  def init(_args) do
    {:ok, :battery_backed_time}
  end


  @impl NervesTime.RealTimeClock
  def terminate(_) do
    :ok
  end

  @doc """
  The system time is trusted, so this implemenation no ops.
  """
  @impl NervesTime.RealTimeClock
  def set_time(_, _naive_date_time) do
    :battery_backed_time
  end

  @doc """
  Always return the system time because the rtc is battery backed.
  """
  @impl NervesTime.RealTimeClock
  def get_time(_rtc) do
    {:ok, NaiveDateTime.utc_now(), :battery_backed_time}
  end
end
