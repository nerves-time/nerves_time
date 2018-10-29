defmodule Nerves.Time.TimestampHandler do
  @moduledoc """
  Nerves Timestamp Handler behaviour.

  ```elixir
  defmodule MyApp.MyRTCHandler do
    use Nerves.Time.TimestampHandler
  end
  ```
  """

  @doc """
  Initializes the handler
  """
  @callback init() :: {:ok, term()} :: {:error, term()}
  @doc """
  Return the stored timestamp of when update was last called.
  """
  @callback time(term()) :: NaiveDateTime.t() | {:error, term()}
  @doc """
  Store current time.
  """
  @callback update(term()) :: :ok | {:error, term()}

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Nerves.Time.TimestampHandler

      @doc false
      def init() do
        raise "Not Implemented. Please check your nerves_time timestamp handler"
      end

      @doc false
      def time(_state) do
        raise "Not Implemented. Please check your nerves_time timestamp handler"
      end

      @doc false
      def update(_state) do
        raise "Not Implemented. Please check your nerves_time timestamp handler"
      end

      defoverridable Nerves.Time.TimestampHandler
    end
  end
end
