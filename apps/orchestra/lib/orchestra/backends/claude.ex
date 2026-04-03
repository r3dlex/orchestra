defmodule Orchestra.Backends.Claude do
  def run(worker_id, {:claude, _}, %{task: task, worktree_path: worktree_path}) do
    escaped = String.replace(task, "\"", "\\\"")
    "cd #{worktree_path} && claude --print --prompt \"#{escaped}\" > .musician/worker-#{worker_id}-result.txt"
  end
end
