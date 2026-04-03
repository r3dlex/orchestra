defmodule Orchestra.Worktree.Report do
  @moduledoc "Generate integration reports for completed worktree work."

  def generate(worker_id, result) do
    status = Map.get(result, :status, :unknown)
    files_changed = Map.get(result, :files_changed, 0)
    "Worker #{worker_id}: status=#{status}, files_changed=#{files_changed}, completed_at=#{DateTime.utc_now() |> DateTime.to_iso8601()}"
  end
end
