defmodule Nerves.NTP do
  @moduledoc """

  """

  @doc """

  """
  defdelegate is_synchronized, to: Nerves.NTP.Worker
end
