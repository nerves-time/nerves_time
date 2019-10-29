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
  @callback retrieve_time() :: NaiveDateTime.t() | :error

  @doc """
  Store current time.
  """
  @callback update_time( ) :: :ok | :error

  @spec module() :: Module.t()
  defp module() do
    Application.get_env(:nerves_time, :hardware_time_module, NervesTime.FileTime)
  end

  @spec time() :: NaiveDateTime.t()
  def time() do
    case module().retrieve_time() do
      :error -> ~N[1970-01-01 00:00:00]
      %NaiveDateTime{} = dt -> dt
    end
  end

  @spec update( ) :: :ok | {:error, term()}
  def update() do
    module().update_time()
  end
end
