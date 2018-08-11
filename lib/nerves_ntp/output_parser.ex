defmodule Nerves.NTP.OutputParser do
  @responses [
    {:bad_address, ~r/ntpd: bad address '(?<server>\S+)'/},
    {:address, ~r/ntpd: '(?<server>\S+)' is (?<address>\S+)/},
    {:query, ~r/ntpd: sending query to (?<address>\S+)/},
    {:timeout,
     ~r/ntpd: timed out waiting for (?<address>\S+), reach (?<reach>0x[0-9a-fA-F]+), next query in (?<next_query>\d+)s/},
    {:reply,
     ~r/ntpd: reply from (?<address>\S+): offset:(?<offset>[+-]?\d*\.\d+)(?![-+0-9\.]) delay:(?<delay>[+-]?\d*\.\d+)(?![-+0-9\.]) status:(?<status>0x[0-9a-fA-F]+) strat:(?<strat>\d+) refid:(?<refid>0x[0-9a-fA-F]+) rootdelay:(?<rootdelay>[+-]?\d*\.\d+)(?![-+0-9\.]) reach:(?<reach>0x[0-9a-fA-F]+)/}
  ]

  @doc """
  Parse a message from Busybox ntpd.

  ```
  iex> Nerves.NTP.OutputParser.parse("ntpd: sending query to 195.78.244.50")
  {:query, %{address: "195.78.244.50"}})
  ```
  """
  @spec parse(String.t()) :: {atom(), map()}
  def parse(message) do
    Enum.find_value(@responses, {:ignored, message}, fn possibility ->
      try_response(possibility, message)
    end)
  end

  defp try_response({type, regex}, message) do
    case Regex.named_captures(regex, message) do
      nil ->
        nil

      captures ->
        {type,
         captures
         |> Enum.map(&parse_capture/1)
         |> Map.new()}
    end
  end

  defp parse_capture({"server", value}), do: {:server, value}
  defp parse_capture({"address", value}), do: {:address, value}
  defp parse_capture({"reach", value}), do: {:reach, parse_int(value)}
  defp parse_capture({"next_query", value}), do: {:next_query, parse_int(value)}
  defp parse_capture({"offset", value}), do: {:offset, parse_float(value)}
  defp parse_capture({"delay", value}), do: {:delay, parse_float(value)}
  defp parse_capture({"status", value}), do: {:status, parse_int(value)}
  defp parse_capture({"strat", value}), do: {:stratum, parse_int(value)}
  defp parse_capture({"refid", value}), do: {:refid, parse_int(value)}
  defp parse_capture({"rootdelay", value}), do: {:rootdelay, parse_float(value)}

  defp parse_int(<<"0x", hex::binary>>), do: String.to_integer(hex, 16)
  defp parse_int(dec), do: String.to_integer(dec)

  defp parse_float(str) do
    {f, _rest} = Float.parse(str)
    f
  end
end
