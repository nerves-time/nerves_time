defmodule Nerves.NTP.SaneTime do
  @build_time DateTime.utc_now() |> DateTime.truncate(:second)
  @newest_time %{@build_time | year: @build_time.year + 20}

  @doc """
  This function takes a guess at the current time and tries to
  adjust it so that it's not obviously wrong.

  Some things that could be wrong:

  * The time is before this module was compiled.
  * The time is 20 years in the future. (Assume that nothing goes 20 years without an update)

  Currently if the time doesn't look right, it's set to the build time.
  """
  def make_sane(possible_time) do
    if DateTime.compare(possible_time, @build_time) == :lt or
         DateTime.compare(possible_time, @newest_time) == :gt do
      @build_time
    else
      possible_time
    end
  end
end
