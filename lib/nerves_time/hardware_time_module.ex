defmodule NervesTime.HardwareTimeModule do
  @moduledoc """
  Nerves Hardware Time Handler behaviour.

  ```elixir
  defmodule MyApp.MyRTCHandler do
    @behaviour NervesTime.HardwareTimeModule
  end
  ```
  """

  @doc """
  Return the stored timestamp from hardware time module.
  """
  @callback time() :: NaiveDateTime.t() | {:error, term()}

  @doc """
  Store current time.
  """
  @callback update( ) :: :ok | {:error, term()}

end
