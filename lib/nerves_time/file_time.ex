defmodule Nerves.Time.FileTime do
  @default_path ".nerves_time"

  @moduledoc false

  @doc """
  Update the file holding a stamp of the current time.
  """
  @spec update() :: :ok | {:error, term()}
  def update() do
    File.touch(time_file())
  end

  @doc """
  Return the timestamp of when update was last called.
  """
  @spec time() :: NaiveDateTime.t() | {:error, term()}
  def time() do
    case File.stat(time_file()) do
      {:ok, stat} ->
        NaiveDateTime.from_erl!(stat.mtime)

      error ->
        error
    end
  end

  @doc """
  Return the path to the file that keeps track of the time
  """
  @spec time_file() :: binary()
  def time_file() do
    Application.get_env(:nerves_time, :time_file, @default_path)
    |> Path.expand(System.user_home())
  end
end
