# SPDX-FileCopyrightText: 2026 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.HTTPTest do
  use ExUnit.Case

  # Simulated response matching the real whenwhere.nerves-project.org format.
  # Coordinates are set to the geographic center of the contiguous United States
  # (Lebanon, KS: 39.8283°N, 98.5795°W).
  # Each header line ends with \r so that combined with the heredoc's \n the
  # resulting string uses the \r\n line endings that HTTP/1.1 requires.
  @whenwhere_response """
  HTTP/1.1 200 OK\r
  Server: CloudFront\r
  Date: Mon, 23 Feb 2026 22:23:38 GMT\r
  Content-Type: application/json\r
  Content-Length: 195\r
  Connection: close\r
  Cache-Control: no-cache, must-revalidate, max-age=0\r
  Expires: 0\r
  X-Now: 2026-02-23T22:23:38.675Z\r
  X-Cache: FunctionGeneratedResponse from cloudfront\r
  Via: 1.1 5fe5f2a3903f1378941d92eceaf3fa16.cloudfront.net (CloudFront)\r
  X-Amz-Cf-Pop: SEA73-P1\r
  X-Amz-Cf-Id: WUPG3HPHDNofLc-eKFKhX2sSrnMDFBHDb33l7lUkqemNnPoHyyr_vA==\r
  \r
  {"now":"2026-02-23T22:23:38.675Z","time_zone":"America/Chicago","latitude":"39.82830","longitude":"-98.57950","country":"US","country_region":"KS","city":"Lebanon","address":"204.8.69.113:51946"}
  """

  # Starts a minimal one-shot HTTP server on a random port. Accepts one
  # connection, drains the request, writes `response`, then closes.
  defp start_fake_server(response) do
    {:ok, listen_sock} =
      :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true])

    {:ok, port} = :inet.port(listen_sock)

    Task.start(fn ->
      case :gen_tcp.accept(listen_sock, 2_000) do
        {:ok, client} ->
          :gen_tcp.recv(client, 0, 2_000)
          :gen_tcp.send(client, response)
          :gen_tcp.close(client)

        _ ->
          :ok
      end

      :gen_tcp.close(listen_sock)
    end)

    port
  end

  test "parses the Date header from a real whenwhere response" do
    port = start_fake_server(@whenwhere_response)

    assert {:ok, ~N[2026-02-23 22:23:38]} =
             NervesTime.HTTP.get_time(servers: ["http://localhost:#{port}/"])
  end
end
