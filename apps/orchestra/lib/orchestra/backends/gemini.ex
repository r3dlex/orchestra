defmodule Orchestra.Backends.Gemini do
  def run(worker_id, {:gemini, _}, %{task: task, worktree_path: worktree_path}) do
    escaped = String.replace(task, "\"", "\\\"")
    "cd #{worktree_path} && gemini -p \"#{escaped}\" > .musician/worker-#{worker_id}-result.txt"
  end
end
