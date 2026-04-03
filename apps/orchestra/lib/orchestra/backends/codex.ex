defmodule Orchestra.Backends.Codex do
  def run(worker_id, {:codex, _}, %{task: task, worktree_path: worktree_path}) do
    escaped = String.replace(task, "\"", "\\\"")
    "cd #{worktree_path} && codex exec --prompt \"#{escaped}\" > .musician/worker-#{worker_id}-result.txt"
  end
end
