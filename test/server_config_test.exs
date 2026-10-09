# SPDX-FileCopyrightText: 2026 Eliel A. Gordon
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.ServerConfigTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  alias NervesTime.ServerConfig

  setup do
    dir = Path.join(System.tmp_dir!(), "nerves_time_server_config_test")
    File.rm_rf!(dir)
    path = Path.join(dir, "ntp_servers")

    on_exit(fn ->
      Application.delete_env(:nerves_time, :servers_file)
      Application.delete_env(:nerves_time, :servers)
      File.rm_rf!(dir)
    end)

    {:ok, dir: dir, path: path}
  end

  describe "get/0" do
    test "falls back to the :servers config when no servers file is configured" do
      Application.delete_env(:nerves_time, :servers_file)
      Application.put_env(:nerves_time, :servers, ["config.example.com"])

      assert ServerConfig.get() == ["config.example.com"]
    end

    test "falls back to the NTP Pool defaults when nothing is configured" do
      Application.delete_env(:nerves_time, :servers_file)
      Application.delete_env(:nerves_time, :servers)

      assert ServerConfig.get() == [
               "0.pool.ntp.org",
               "1.pool.ntp.org",
               "2.pool.ntp.org",
               "3.pool.ntp.org"
             ]
    end

    test "falls back to :servers when the file is configured but absent", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)
      Application.put_env(:nerves_time, :servers, ["config.example.com"])

      assert ServerConfig.get() == ["config.example.com"]
    end

    test "prefers the persisted file over :servers when present", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)
      Application.put_env(:nerves_time, :servers, ["should.be.ignored"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "1.2.3.4\n")

      assert ServerConfig.get() == ["1.2.3.4"]
    end

    test "a present-but-empty file is honored as NTP disabled", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)
      Application.put_env(:nerves_time, :servers, ["should.be.ignored"])
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "# NTP disabled\n")

      assert ServerConfig.get() == []
    end

    test "ignores blank lines and comments when parsing", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "# a comment\n\n  1.2.3.4  \n\n2.3.4.5\n")

      assert ServerConfig.get() == ["1.2.3.4", "2.3.4.5"]
    end
  end

  describe "put/1" do
    test "round-trips a server list through get/0", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)

      assert :ok = ServerConfig.put(["1.2.3.4", "time.example.com"])
      assert ServerConfig.get() == ["1.2.3.4", "time.example.com"]
    end

    test "creates intermediate directories when saving", %{dir: dir} do
      path = Path.join([dir, "nested", "deeper", "ntp_servers"])
      Application.put_env(:nerves_time, :servers_file, path)

      assert :ok = ServerConfig.put(["1.2.3.4"])
      assert File.exists?(path)
    end

    test "persists an empty list so it survives a reboot", %{path: path} do
      Application.put_env(:nerves_time, :servers_file, path)

      assert :ok = ServerConfig.put([])
      # The file is present (so it takes precedence over :servers) but yields [].
      assert File.exists?(path)
      assert ServerConfig.get() == []
    end

    test "is a no-op returning :ok when not configured" do
      Application.delete_env(:nerves_time, :servers_file)
      assert :ok = ServerConfig.put(["1.2.3.4"])
    end

    test "returns and logs an error when the file can't be written", %{dir: dir} do
      # Point at a path whose parent is a regular file so mkdir_p fails.
      blocker = Path.join(dir, "blocker")
      File.mkdir_p!(dir)
      File.write!(blocker, "")
      path = Path.join(blocker, "ntp_servers")
      Application.put_env(:nerves_time, :servers_file, path)

      log =
        capture_log(fn ->
          assert {:error, _reason} = ServerConfig.put(["1.2.3.4"])
        end)

      assert log =~ "Failed to persist servers file"
    end
  end
end
