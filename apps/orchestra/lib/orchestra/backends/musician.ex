defmodule Orchestra.Backends.Musician do
  def run(worker_id, {:musician, provider}, %{task: task, worktree_path: worktree_path}) do
    escaped = String.replace(task, "\"", "\\\"")
    "cd #{worktree_path} && musician --provider #{provider} --non-interactive --prompt \"#{escaped}\" --output-file .musician/worker-#{worker_id}-result.json"
  end
end
