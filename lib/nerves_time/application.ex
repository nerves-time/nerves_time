# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Benjamin Milde
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesTime.Application do
  @moduledoc false
  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    children = [
      NervesTime.SystemTime,
      NervesTime.Ntpd,
      NervesTime.Waiter
    ]

    opts = [strategy: :one_for_one, name: NervesTime.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
