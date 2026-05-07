# SPDX-FileCopyrightText: 2018 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTimeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest NervesTime

  @fixtures Path.expand("fixtures", __DIR__)
  defp fixture_path(fixture) do
    Path.join(@fixtures, fixture)
  end

  defp send_ntpd_report(report, env \\ []) do
    ntpd_script_path = Application.app_dir(:nerves_time, ["priv", "ntpd_script"])
    socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")

    default_env = %{
      "freq_drift_ppm" => "0",
      "offset" => "0.0",
      "stratum" => "16",
      "poll_interval" => "1",
      "SOCKET_PATH" => socket_path
    }

    merged_env =
      env
      |> Enum.into(%{}, fn {key, value} -> {to_string(key), value} end)
      |> then(&Map.merge(default_env, &1))
      |> Enum.to_list()

    {_, 0} = System.cmd(ntpd_script_path, [report], env: merged_env)
    :ok
  end

  setup do
    capture_log(fn ->
      Application.stop(:nerves_time)
      socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")
      File.rm(socket_path)
    end)

    :ok
  end

  test "reports that time synchronized when told" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)

    # The fake_busybox_ntpd should have reported synchronization by this time.
    assert NervesTime.synchronized?()

    assert %{
             synchronized?: true,
             last_sync_report: %{stratum: 3},
             sync_acquired_at: %DateTime{},
             last_sync_at: %DateTime{}
           } = NervesTime.sync_status()
  end

  test "reports that time not synchronized when net is down" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    Process.sleep(100)

    refute NervesTime.synchronized?()

    assert %{
             synchronized?: false,
             last_sync_report: nil,
             sync_acquired_at: nil,
             last_sync_at: nil
           } =
             NervesTime.sync_status()
  end

  test "reports that time not synchronized when stratum 16" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_stratum16"))
    Application.start(:nerves_time)
    Process.sleep(100)

    refute NervesTime.synchronized?()
    assert NervesTime.Ntpd.clean_start?()
  end

  test "delays ntpd restart after a GenServer crash" do
    # This one should be clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    assert NervesTime.Ntpd.clean_start?()

    # Kill it...
    Process.exit(Process.whereis(NervesTime.Ntpd), :oops)
    Process.sleep(100)

    refute NervesTime.Ntpd.clean_start?()
  end

  test "delays ntpd restart after a ntpd crash" do
    # Try a run that crashes
    log =
      capture_log(fn ->
        Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_crash"))
        Application.start(:nerves_time)
        Process.sleep(100)

        # Even if a healthy ntpd becomes available immediately, the delayed
        # restart should prevent quick re-synchronization after a crash.
        Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
        Process.sleep(500)

        refute NervesTime.synchronized?()
      end)

    assert log =~ ~r/fake_busybox_ntpd_crash: Process exited with status 1/
    assert log =~ "ntpd crash detected. Delaying next start..."

    # Restore env.
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
  end

  test "manual ntpd restart is clean" do
    # Start clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    assert NervesTime.Ntpd.clean_start?()

    # Kill it...
    Process.exit(Process.whereis(NervesTime.Ntpd), :oops)
    Process.sleep(100)

    refute NervesTime.Ntpd.clean_start?()
    refute NervesTime.synchronized?()

    # Force a restart
    # NOTE: This is actually a start, since the unclean run above will
    #       not have started ntpd yet.
    NervesTime.restart_ntpd()

    # This should be clean now.
    assert NervesTime.Ntpd.clean_start?()
  end

  test "can restart ntpd" do
    # Start clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    # Wait for synchronization so that we can also check that
    # synchronization goes away on restart
    Process.sleep(100)
    assert NervesTime.Ntpd.clean_start?()
    assert NervesTime.synchronized?()

    # Force a restart
    NervesTime.restart_ntpd()

    # Clean start, but not synchronized.
    refute NervesTime.synchronized?()
    assert NervesTime.Ntpd.clean_start?()

    # Check that it synchronizes
    Process.sleep(100)
    assert NervesTime.synchronized?()
  end

  test "can set servers at runtime" do
    # Start with no servers
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.put_env(:nerves_time, :servers, [])
    Application.start(:nerves_time)

    # No synchronization since no servers
    Process.sleep(100)
    assert NervesTime.Ntpd.clean_start?()
    refute NervesTime.synchronized?()

    # Set the servers...
    NervesTime.set_ntp_servers(["1.2.3.4"])

    # Check that it synchronizes
    Process.sleep(100)
    assert NervesTime.synchronized?()

    # Use the defaults for servers for the other tests.
    Application.delete_env(:nerves_time, :servers)
  end

  test "resynchronizes after unsync report" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)

    assert NervesTime.synchronized?()

    # Send an "unsync" report directly to the running GenServer's socket
    ntpd_script_path = Application.app_dir(:nerves_time, ["priv", "ntpd_script"])
    socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")

    log =
      capture_log(fn ->
        System.cmd(ntpd_script_path, ["unsync"],
          env: [
            {"freq_drift_ppm", "0"},
            {"offset", "0.0"},
            {"stratum", "16"},
            {"poll_interval", "1"},
            {"SOCKET_PATH", socket_path}
          ]
        )
      end)

    assert log =~ "ntpd reports that it is unsynchronized; restarting"

    # Wait for ntpd to restart
    Process.sleep(500)

    # We should be able to sync now
    assert NervesTime.synchronized?()
  end

  test "changing servers at runtime resets synchronization" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    # Check synchronization with default set
    Process.sleep(100)
    assert NervesTime.Ntpd.clean_start?()
    assert NervesTime.synchronized?()

    # Change the servers...
    NervesTime.set_ntp_servers(["1.2.3.4"])

    # Verify that we're no longer synchronized.
    refute NervesTime.synchronized?()

    # Check for eventual synchronization
    Process.sleep(100)
    assert NervesTime.synchronized?()
  end

  test "subscribers receive NTP daemon events" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    NervesTime.subscribe()

    assert_receive {:nerves_time, :sync_status,
                    %{
                      synchronized?: false,
                      last_sync_report: nil,
                      sync_acquired_at: nil,
                      last_sync_at: nil
                    }},
                   200

    send_ntpd_report("stratum",
      stratum: "3",
      offset: "0.125",
      poll_interval: "4",
      freq_drift_ppm: "2"
    )

    assert_receive {:nerves_time, :sync_acquired,
                    %{freq_drift_ppm: 2, offset: 0.125, stratum: 3, poll_interval: 4}},
                   200

    assert %{sync_acquired_at: sync_acquired_at, last_sync_at: first_last_sync_at} =
             NervesTime.sync_status()

    assert %DateTime{} = sync_acquired_at
    assert %DateTime{} = first_last_sync_at

    send_ntpd_report("periodic", stratum: "2", offset: "0.25")

    assert_receive {:nerves_time, :sync_updated,
                    %{freq_drift_ppm: 0, offset: 0.25, stratum: 2, poll_interval: 1}},
                   200

    assert %{
             synchronized?: true,
             last_sync_report: %{stratum: 2},
             sync_acquired_at: ^sync_acquired_at,
             last_sync_at: second_last_sync_at
           } = NervesTime.sync_status()

    assert DateTime.compare(second_last_sync_at, first_last_sync_at) in [:eq, :gt]

    send_ntpd_report("step", stratum: "2", offset: "1.5")

    assert_receive {:nerves_time, :clock_step,
                    %{freq_drift_ppm: 0, offset: 1.5, stratum: 2, poll_interval: 1}},
                   200
  end

  test "subscribers receive sync_lost events" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    NervesTime.subscribe()

    assert_receive {:nerves_time, :sync_status,
                    %{
                      synchronized?: false,
                      last_sync_report: nil,
                      sync_acquired_at: nil,
                      last_sync_at: nil
                    }},
                   200

    log =
      capture_log(fn ->
        send_ntpd_report("unsync", stratum: "16")

        assert_receive {:nerves_time, :sync_lost,
                        %{freq_drift_ppm: 0, offset: offset, stratum: 16, poll_interval: 1}},
                       200

        assert offset in [0.0, -0.0]
      end)

    assert log =~ "ntpd reports that it is unsynchronized; restarting"
  end

  test "sync status preserves last successful sync details after sync is lost" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)

    assert %{
             synchronized?: true,
             last_sync_report: initial_report,
             sync_acquired_at: sync_acquired_at,
             last_sync_at: last_sync_at
           } = NervesTime.sync_status()

    assert %DateTime{} = sync_acquired_at
    assert %DateTime{} = last_sync_at
    assert %{stratum: 3} = initial_report

    ntpd_script_path = Application.app_dir(:nerves_time, ["priv", "ntpd_script"])
    socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")

    capture_log(fn ->
      System.cmd(ntpd_script_path, ["unsync"],
        env: [
          {"freq_drift_ppm", "0"},
          {"offset", "0.0"},
          {"stratum", "16"},
          {"poll_interval", "1"},
          {"SOCKET_PATH", socket_path}
        ]
      )
    end)

    assert %{
             synchronized?: false,
             last_sync_report: ^initial_report,
             sync_acquired_at: ^sync_acquired_at,
             last_sync_at: ^last_sync_at
           } = NervesTime.sync_status()
  end

  test "unsubscribe stops event delivery" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    NervesTime.subscribe()
    assert_receive {:nerves_time, :sync_status, _}, 200
    NervesTime.unsubscribe()

    send_ntpd_report("step")

    refute_receive {:nerves_time, :clock_step, _}, 200
  end

  test "subscribe sends the current sync status snapshot" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)
    NervesTime.subscribe()

    assert_receive {:nerves_time, :sync_status,
                    %{
                      synchronized?: true,
                      last_sync_report: %{stratum: 3},
                      sync_acquired_at: %DateTime{},
                      last_sync_at: %DateTime{}
                    }},
                   200
  end

  test "subscriber processes are removed when they exit" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)

    subscriber =
      spawn(fn ->
        NervesTime.subscribe()
        Process.sleep(:infinity)
      end)

    Process.sleep(50)
    assert Map.has_key?(:sys.get_state(NervesTime.Ntpd).subscribers, subscriber)

    Process.exit(subscriber, :kill)
    Process.sleep(50)

    refute Map.has_key?(:sys.get_state(NervesTime.Ntpd).subscribers, subscriber)
  end
end
