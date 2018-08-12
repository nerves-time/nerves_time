defmodule Nerves.Time.SaneTime do
  @build_time NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
  @newest_time %{@build_time | year: @build_time.year + 20}

  @moduledoc false

  @doc """
  Figure out a guess of the real time based on the current system clock (possible_time)
  and the latest timestamp from FileTime.
  """
  def derive_time(possible_time, file_time) do
    # First normalize the input times so that they're in a reasonable time interval
    sane_file_time = make_sane(file_time)
    sane_possible_time = make_sane(possible_time)

    # Pick the latest
    if NaiveDateTime.compare(sane_possible_time, sane_file_time) == :gt do
      sane_possible_time
    else
      sane_file_time
    end
  end

  @doc """
  This function takes a guess at the current time and tries to adjust it so
  that it's not obviously wrong.

  Some things that could be wrong:

  * The time is before this module was compiled.
  * The time is 20 years in the future. (Assume that nothing goes 20 years without an update)

  Currently if the time doesn't look right, it's set to the build time.
  """
  def make_sane(time) do
    if is_sane(time) do
      time
    else
      @build_time
    end
  end

  defp is_sane(%NaiveDateTime{} = time) do
    NaiveDateTime.compare(time, @build_time) == :gt and
      NaiveDateTime.compare(time, @newest_time) == :lt
  end

  defp is_sane(_something_else), do: false
end
