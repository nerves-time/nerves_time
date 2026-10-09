# SPDX-FileCopyrightText: 2026 Eliel A. Gordon
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.ServerConfig do
  @moduledoc false
  # Resolves and persists the NTP server list across its possible sources.
  #
  # In precedence order, the servers come from:
  #
  #   1. the durable runtime file named by the `:servers_file` application key,
  #      when configured and present
  #   2. the static `:servers` application key
  #   3. the built-in NTP Pool defaults
  #
  # When `:servers_file` is configured, the list set via
  # `NervesTime.set_ntp_servers/1` is written there so the choice survives a
  # reboot. The presence of the file is the signal to use the persisted list:
  # an empty list is stored as an explicit "NTP disabled" marker so that turning
  # NTP off also survives a reboot. When `:servers_file` is not configured,
  # persistence is a no-op and only the static config is consulted.
  require Logger

  @default_ntp_servers [
    "0.pool.ntp.org",
    "1.pool.ntp.org",
    "2.pool.ntp.org",
    "3.pool.ntp.org"
  ]

  @doc """
  Return the NTP servers to use.

  Prefers the persisted `:servers_file` when configured and present, otherwise
  falls back to the `:servers` application key (defaulting to the NTP Pool). A
  persisted empty list is honored as "NTP disabled".
  """
  @spec get() :: [String.t()]
  def get() do
    case load_file() do
      {:ok, servers} -> servers
      :not_present -> Application.get_env(:nerves_time, :servers, @default_ntp_servers)
    end
  end

  @doc """
  Persist a normalized NTP server list.

  Returns `:ok` on success or when no servers file is configured (a no-op).
  Returns `{:error, reason}` and logs the failure when the file can't be
  written.
  """
  @spec put([String.t()]) :: :ok | {:error, term()}
  def put(servers) when is_list(servers) do
    case file_path() do
      nil -> :ok
      file -> write_file(file, servers)
    end
  end

  defp file_path() do
    Application.get_env(:nerves_time, :servers_file)
  end

  # Returns `{:ok, servers}` when the file exists (servers may be `[]`), or
  # `:not_present` when no file is configured, it doesn't exist yet, or it
  # couldn't be read (in which case the failure is logged).
  defp load_file() do
    case file_path() do
      nil ->
        :not_present

      file ->
        case File.read(file) do
          {:ok, contents} ->
            {:ok, parse(contents)}

          {:error, :enoent} ->
            :not_present

          {:error, reason} ->
            Logger.warning(
              "[NervesTime] Failed to read servers file #{inspect(file)}: #{inspect(reason)}"
            )

            :not_present
        end
    end
  end

  defp parse(contents) do
    contents
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
  end

  defp write_file(file, servers) do
    with :ok <- file |> Path.dirname() |> File.mkdir_p(),
         :ok <- File.write(file, format(servers)) do
      :ok
    else
      {:error, reason} = error ->
        Logger.warning(
          "[NervesTime] Failed to persist servers file #{inspect(file)}: #{inspect(reason)}"
        )

        error
    end
  end

  # An empty list still writes a file so that the "NTP disabled" choice is
  # distinguishable from "no file persisted yet" on the next boot.
  defp format([]), do: "# NTP disabled\n"
  defp format(servers), do: Enum.map_join(servers, "\n", & &1) <> "\n"
end
