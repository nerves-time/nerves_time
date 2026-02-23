# SPDX-FileCopyrightText: 2026 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.TimeSource do
  @moduledoc """
  Behaviour for supplemental time sources.

  Supplemental time sources provide a way to set the system clock when NTP has
  not yet synchronized or is unavailable. They are purely functional — no
  process or persistent state is required.

  Sources are tried in the order they appear in the `:time_sources` config list.
  The first source to return `{:ok, datetime}` wins and sets the system clock.
  Once NTP synchronizes, supplemental sources are skipped.

  ## Example implementation

      defmodule MyApp.CustomTimeSource do
        @behaviour NervesTime.TimeSource

        @impl NervesTime.TimeSource
        def get_time(_opts) do
          case fetch_time_somehow() do
            {:ok, naive_dt} -> {:ok, naive_dt}
            error -> {:error, error}
          end
        end
      end

  Configure it alongside the built-in sources:

      config :nerves_time, :time_sources, [
        {NervesTime.HTTP, servers: ["http://whenwhere.nerves-project.org/"]},
        {MyApp.CustomTimeSource, []}
      ]
  """

  @doc """
  Attempt to obtain the current UTC time.

  Returns `{:ok, %NaiveDateTime{}}` on success, or `{:error, reason}` if the
  source is unavailable or returns an unusable result.

  `opts` are the keyword list provided alongside the module in `:time_sources`
  config.
  """
  @callback get_time(opts :: keyword()) :: {:ok, NaiveDateTime.t()} | {:error, reason :: term()}
end
