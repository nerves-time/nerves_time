defmodule NervesTime.FileTime do
  @default_path ".nerves_time"
  @behaviour NervesTime.RealTimeClock

  @moduledoc false

  @typep state :: any()

  @doc false
  @impl NervesTime.RealTimeClock
  @spec init(args :: any()) :: {:ok, state}
  def init(args), do: {:ok, args}

  @doc """
  Update the file holding a stamp of the current time.
  """
  @impl NervesTime.RealTimeClock
  @spec update(state) :: :ok | {:error, File.posix()}
  def update(_state) do
    File.touch(time_file())
  end

  @doc """
  Return the timestamp of when update was last called or
  the Unix epoch time (1970-01-01) should that not work.
  """
  @impl NervesTime.RealTimeClock
  @spec time(state) :: NaiveDateTime.t()
  def time(_state) do
    case File.stat(time_file()) do
      {:ok, stat} ->
        NaiveDateTime.from_erl!(stat.mtime)

      _error ->
        ~N[1970-01-01 00:00:00]
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
