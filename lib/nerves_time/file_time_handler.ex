defmodule Nerves.Time.FileTimeHandler do
  use Nerves.Time.TimestampHandler

  @default_path ".nerves_time"

  @moduledoc false

  @impl true
  def init() do
    time_file = Application.get_env(:nerves_time, :time_file, @default_path) |> Path.expand(System.user_home())

    {:ok, %{time_file: time_file}}
  end

  @doc """
  Update the file holding a stamp of the current time.
  """
  @impl true
  def update(%{time_file: time_file}) do
    File.touch(time_file)
  end

  @doc """
  Return the timestamp of when update was last called.
  """
  @impl true
  def time(%{time_file: time_file}) do
    case File.stat(time_file) do
      {:ok, stat} ->
        NaiveDateTime.from_erl!(stat.mtime)

      error ->
        error
    end
  end
end
