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
  @spec time(state) :: {:ok, NaiveDateTime.t()} | {:error, any()}
  def time(_state) do
    with {:ok, stat} <- File.stat(time_file()),
         {:ok, %NaiveDateTime{} = mtime} <- NaiveDateTime.from_erl(stat.mtime) do
      {:ok, mtime}
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
