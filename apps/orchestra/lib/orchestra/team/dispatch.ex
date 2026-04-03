defmodule Orchestra.Team.Dispatch do
  @moduledoc "Route tasks to available backends."

  def route([], _task, _context), do: {:error, :no_backends}

  def route(backends, _task, _context) do
    # Simple round-robin: pick first available backend
    List.first(backends)
  end
end
