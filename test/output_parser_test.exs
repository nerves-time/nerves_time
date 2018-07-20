defmodule OutputParserTest do
  use ExUnit.Case

  alias Nerves.NTP.OutputParser

  test "decodes addresses" do
    assert OutputParser.parse("ntpd: bad address '0.pool.ntp.org'") == {:bad_address, %{server: "0.pool.ntp.org"}}
    assert OutputParser.parse("ntpd: '1.pool.ntp.org' is 195.78.244.50") == {:address, %{server: "1.pool.ntp.org", address: "195.78.244.50"}}
  end

  test "decodes requests" do
    assert OutputParser.parse("ntpd: sending query to 195.78.244.50") == {:query, "195.78.244.50"}
  end

  test "decodes responses" do
    {:reply, result} = OutputParser.parse("ntpd: reply from 35.237.173.121: offset:-0.000109 delay:0.018289 status:0x24 strat:3 refid:0xfea9fea9 rootdelay:0.000916 reach:0x03")
    assert result.address == "35.237.173.121"
    assert result.offset == -0.000109
    assert result.delay == 0.018289
    assert result.status == 0x24
    assert result.stratum == 3
    assert result.refid == 0xfea9fea9
    assert result.rootdelay == 0.000916
    assert result.reach == 0x03
  end

  test "decodes timeout" do
    {:timeout, result} = OutputParser.parse("ntpd: timed out waiting for 35.237.173.121, reach 0x06, next query in 33s")
    assert result.address == "35.237.173.121"
    assert result.reach == 0x06
    assert result.next_query == 33
  end

  test "ignores junk" do
    assert OutputParser.parse("\n") == {:ignored, "\n"}
    assert OutputParser.parse("something") == {:ignored, "something"}
    assert OutputParser.parse("ntpd: new stuff") == {:ignored, "ntpd: new stuff"}
  end
end
