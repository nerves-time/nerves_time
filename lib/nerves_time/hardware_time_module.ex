defmodule NervesTime.HardwareTimeModule do
  require Logger

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
  @callback update_time() :: :ok | :error

  @spec module() :: Module.t()
  defp module() do
    Application.get_env(:nerves_time, :hardware_time_module, NervesTime.FileTime)
  end

  @spec time() :: NaiveDateTime.t()
  def time() do
    try do
      case module().retrieve_time() do
        :error ->
          ~N[1970-01-01 00:00:00]
        %NaiveDateTime{} = dt ->
          dt
      end
    rescue
      e ->
        Logger.error("Unexpected error retrieving HW Time: #{inspect e}")
        ~N[1970-01-01 00:00:00]
    end
  end

  @spec update( ) :: :ok | :error
  def update() do
    try do
      module().update_time()
    rescue
      e ->
        Logger.error("Unexpected error setting HW Time: #{inspect e}")
        :error
    end
  end
end
