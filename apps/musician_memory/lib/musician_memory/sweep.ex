defmodule MusicianMemory.Sweep do
  @moduledoc """
  Background GenServer that runs DecaySweeper on a 24-hour interval.

  The sweep runs once at startup and then every 24 hours thereafter.
  """

  use GenServer

  @interval :timer.hours(24)

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_sweep()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    MusicianMemory.DecaySweeper.run()
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @interval)
  end
end
