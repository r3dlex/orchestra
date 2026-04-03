defmodule Orchestra.Team.Worker do
  @moduledoc "Spawn a worker in a tmux pane for a given backend."

  def spawn(worker_id, backend, _task, _worktree_path) do
    pane = Orchestra.Tmux.Pane.create(worker_id)
    worker = %{
      id: worker_id,
      pane: pane,
      backend: backend,
      status: :running,
      started_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    {:ok, worker}
  end
end
