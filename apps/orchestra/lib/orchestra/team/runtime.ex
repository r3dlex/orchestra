defmodule Orchestra.Team.Runtime do
  @moduledoc "Team FSM: idle → planning → executing → verifying → done | fixing"

  def transition({:idle, state}, {:start, task}) do
    {:planning, Map.put(state, :task, task)}
  end

  def transition({:planning, state}, :ready) do
    {:executing, Map.put(state, :workers, [])}
  end

  def transition({:executing, state}, :all_done) do
    {:verifying, state}
  end

  def transition({:verifying, state}, :pass) do
    {:done, Map.put(state, :completed_at, DateTime.utc_now() |> DateTime.to_iso8601())}
  end

  def transition({:verifying, state}, :fail) do
    retry = Map.get(state, :retry_count, 0) + 1
    {:fixing, Map.put(state, :retry_count, retry)}
  end

  def transition({:fixing, state}, :ready) do
    {:executing, state}
  end

  def transition({phase, state}, event) do
    {:error, {:invalid_transition, phase, event, state}}
  end
end
