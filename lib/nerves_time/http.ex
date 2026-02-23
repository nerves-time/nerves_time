# SPDX-FileCopyrightText: 2026 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.HTTP do
  @moduledoc """
  HTTP-based supplemental time source.

  Obtains the current time by making an HTTP HEAD or GET request and reading
  the `Date` response header. This works with any standard HTTP server and
  requires no special server-side support beyond returning a well-formed `Date`
  header in RFC 2822 format.

  ## Configuration

      config :nerves_time, :time_sources, [
        {NervesTime.HTTP, servers: ["http://whenwhere.nerves-project.org/"]}
      ]

  Multiple servers may be specified. They are tried in order and the first
  successful response is used.
  """

  @behaviour NervesTime.TimeSource

  require Logger

  @impl NervesTime.TimeSource
  def get_time(opts) do
    servers = opts[:servers] || ["http://whenwhere.nerves-project.org/"]
    try_servers(servers)
  end

  defp try_servers([]), do: {:error, :no_valid_server}

  defp try_servers([server | rest]) do
    with {:ok, {_status, headers, _body}} <- :httpc.request(to_charlist(server)),
         {:ok, datetime} <- datetime_from_headers(headers) do
      {:ok, datetime}
    else
      err ->
        Logger.warning("[NervesTime] HTTP time source failed for #{server}: #{inspect(err)}")
        try_servers(rest)
    end
  end

  defp datetime_from_headers([]), do: {:error, :missing_date_header}

  defp datetime_from_headers([{~c"date", value} | _]) do
    case to_string(value) |> String.split() do
      [_day_name, dd, month, yyyy, time, "GMT"] ->
        NaiveDateTime.from_iso8601("#{yyyy}-#{month_to_number(month)}-#{dd}T#{time}")

      _ ->
        {:error, :invalid_date_header}
    end
  end

  defp datetime_from_headers([_ | rest]), do: datetime_from_headers(rest)

  defp month_to_number("Jan" <> _), do: "01"
  defp month_to_number("Feb" <> _), do: "02"
  defp month_to_number("Mar" <> _), do: "03"
  defp month_to_number("Apr" <> _), do: "04"
  defp month_to_number("May" <> _), do: "05"
  defp month_to_number("Jun" <> _), do: "06"
  defp month_to_number("Jul" <> _), do: "07"
  defp month_to_number("Aug" <> _), do: "08"
  defp month_to_number("Sep" <> _), do: "09"
  defp month_to_number("Oct" <> _), do: "10"
  defp month_to_number("Nov" <> _), do: "11"
  defp month_to_number("Dec" <> _), do: "12"
end
