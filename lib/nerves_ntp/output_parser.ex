defmodule Nerves.NTP.OutputParser do
  @responses [{:bad_address, ~r/ntpd: bad address '(?<server>\S+)'/},
              {:address, ~r/ntpd: '(?<server>\S+)' is (?<address>\S+)/}]

  def parse(message) do
    Enum.find_value(@responses, {:ignored, message}, fn possibility -> try_response(possibility, message) end)
  end

  defp try_response({type, regex}, message) do
    Regex.named_captures(regex, message)
    |> captures_to_map(type)
  end

  defp captures_to_map(nil, _type), do: nil

  defp captures_to_map(captures, type) do
    {type, atomize_keys(captures)}
  end

  defp atomize_keys(captures) do
    Enum.reduce(captures, %{}, fn {k, v}, acc -> Map.put(acc, String.to_atom(k), v) end )
  end
end
