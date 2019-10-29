defmodule NervesTime.FileTime do
  @behaviour NervesTime.HardwareTimeModule

  @default_path ".nerves_time"

  @moduledoc false

  @doc """
  Update the file holding a stamp of the current time.
  """
  @spec update_time( ) :: :ok | :error
  def update_time( ) do
    case File.touch(time_file()) do
      :ok -> :ok
      {:error, _err} -> :error
    end
  end

  @doc """
  Return the timestamp of when update was last called or
  the Unix epoch time (1970-01-01) should that not work.
  """
  @spec retrieve_time() :: NaiveDateTime.t() | :error
  def retrieve_time() do
    case File.stat(time_file()) do
      {:ok, stat} ->
        NaiveDateTime.from_erl!(stat.mtime)

      _error ->
        :error
    end
  end

  @doc """
  Return the path to the file that keeps track of the time
  """
  @spec time_file() :: Path.t()
  def time_file() do
    Application.get_env(:nerves_time, :time_file, @default_path)
    |> Path.expand(System.user_home())
  end
end
