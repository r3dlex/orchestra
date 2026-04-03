defmodule Orchestra.Worktree.Merge do
  @moduledoc "Merge worktree changes back to main branch."

  def merge(source_branch, target_branch) do
    cmd = "git merge #{source_branch} --no-ff -m 'Orchestra: merge #{source_branch} into #{target_branch}'"
    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, {:exit_code, code, output}}
    end
  end
end
