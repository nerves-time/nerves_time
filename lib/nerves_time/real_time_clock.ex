defmodule NervesTime.RealTimeClock do
  @moduledoc """
  Behaviour for hardware based real time clocks.
  """

  @typedoc "Internal state of the hardware clock"
  @type state :: any()

  @doc """
  Initialize the hardware clock.
  Called once when `ntpd` boots.
  """
  @callback init(args :: any()) :: {:ok, state} | {:error, reason :: any()}

  @doc """
  Retrieve the time from the hardware clock.
  Called every time a stratum comes in from `ntpd`
  """
  @callback time(state) :: NaiveDateTime.t() | {:error, reason :: any()}

  @doc """
  Set a time to the hardware clock.
  Called every time a stratum comes in from `ntpd`
  """
  @callback update(state) :: :ok | {:error, reason :: any()}
end
