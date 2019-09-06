defmodule NervesTimeTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  doctest Nerves.Time

  @fixtures Path.expand("fixtures", __DIR__)
  defp fixture_path(fixture) do
    Path.join(@fixtures, fixture)
  end

  setup do
    capture_log(fn ->
      Application.stop(:nerves_time)
      socket_path = Path.join(System.tmp_dir!(), "nerves_time_comm")
      File.rm(socket_path)
    end)

    on_exit(fn ->
      nil
    end)

    :ok
  end

  test "reports that time synchronized when told" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)
    Process.sleep(100)

    # The fake_busybox_ntpd should have reported synchronization by this time.
    assert Nerves.Time.synchronized?()
  end

  test "reports that time not synchronized when net is down" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_net_down"))
    Application.start(:nerves_time)
    Process.sleep(100)

    refute Nerves.Time.synchronized?()
  end

  test "delays ntpd restart after a GenServer crash" do
    # This one should be clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    assert Nerves.Time.Ntpd.clean_start?()

    # Kill it...
    Process.exit(Process.whereis(Nerves.Time.Ntpd), :oops)
    Process.sleep(100)

    refute Nerves.Time.Ntpd.clean_start?()
  end

  test "delays ntpd restart after a ntpd crash" do
    # Try a run that crashes
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd_crash"))
    Application.start(:nerves_time)
    Process.sleep(100)

    refute Nerves.Time.Ntpd.clean_start?()

    # Restore env.
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
  end

  test "manual ntpd restart is clean" do
    # Start clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    assert Nerves.Time.Ntpd.clean_start?()

    # Kill it...
    Process.exit(Process.whereis(Nerves.Time.Ntpd), :oops)
    Process.sleep(100)

    refute Nerves.Time.Ntpd.clean_start?()
    refute Nerves.Time.synchronized?()

    # Force a restart
    # NOTE: This is actually a start, since the unclean run above will
    #       not have started ntpd yet.
    Nerves.Time.restart_ntpd()

    # This should be clean now.
    assert Nerves.Time.Ntpd.clean_start?()
  end

  test "can restart ntpd" do
    # Start clean
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    # Wait for synchronization so that we can also check that
    # synchronization goes away on restart
    Process.sleep(100)
    assert Nerves.Time.Ntpd.clean_start?()
    assert Nerves.Time.synchronized?()

    # Force a restart
    Nerves.Time.restart_ntpd()

    # Clean start, but not synchronized.
    refute Nerves.Time.synchronized?()
    assert Nerves.Time.Ntpd.clean_start?()

    # Check that it synchronizes
    Process.sleep(100)
    assert Nerves.Time.synchronized?()
  end

  test "can set servers at runtime" do
    # Start with no servers
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.put_env(:nerves_time, :servers, [])
    Application.start(:nerves_time)

    # No synchronization since no servers
    Process.sleep(100)
    assert Nerves.Time.Ntpd.clean_start?()
    refute Nerves.Time.synchronized?()

    # Set the servers...
    Nerves.Time.set_ntp_servers(["1.2.3.4"])

    # Check that it synchronizes
    Process.sleep(100)
    assert Nerves.Time.synchronized?()

    # Use the defaults for servers for the other tests.
    Application.delete_env(:nerves_time, :servers)
  end

  test "changing servers at runtime resets synchronization" do
    Application.put_env(:nerves_time, :ntpd, fixture_path("fake_busybox_ntpd"))
    Application.start(:nerves_time)

    # Check synchronization with default set
    Process.sleep(100)
    assert Nerves.Time.Ntpd.clean_start?()
    assert Nerves.Time.synchronized?()

    # Change the servers...
    Nerves.Time.set_ntp_servers(["1.2.3.4"])

    # Verify that we're no longer synchronized.
    refute Nerves.Time.synchronized?()

    # Check for eventual synchronization
    Process.sleep(100)
    assert Nerves.Time.synchronized?()
  end
end
