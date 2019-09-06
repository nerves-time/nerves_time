defmodule NtpdParserTest do
  use ExUnit.Case

  defp run_ntpd_script(report, freq_drift_ppm, offset, stratum, poll_interval) do
    rand = Integer.to_string(:rand.uniform(0x100000000), 36) |> String.downcase()
    socket_path = Path.join(System.tmp_dir!(), "nerves_time_test-#{rand}")

    {:ok, socket} =
      :gen_udp.open(0, [:local, :binary, {:active, true}, {:ip, {:local, socket_path}}])

    ntpd_script_path = Application.app_dir(:nerves_time, ["priv", "ntpd_script"])

    {_, 0} =
      System.cmd(ntpd_script_path, [report],
        env: [
          {"freq_drift_ppm", to_string(freq_drift_ppm)},
          {"offset", to_string(offset)},
          {"stratum", to_string(stratum)},
          {"poll_interval", to_string(poll_interval)},
          {"SOCKET_PATH", socket_path}
        ]
      )

    Process.sleep(100)
    File.rm!(socket_path)

    receive do
      {:udp, ^socket, _, 0, data} ->
        :erlang.binary_to_term(data)
    after
      50 ->
        flunk("Didn't receive a message from ntpd_script")
    end
  end

  test "script sends a message to Elixir" do
    assert {"stratum", 1, 0.5, 4, 5} == run_ntpd_script("stratum", 1, 0.5, 4, 5)
  end
end
