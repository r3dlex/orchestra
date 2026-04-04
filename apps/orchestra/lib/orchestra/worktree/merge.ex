defmodule Orchestra.Worktree.Merge do
  @moduledoc "Merge worktree changes back to main branch."

  def merge(source_branch, target_branch) do
    cmd =
      "git merge #{source_branch} --no-ff -m 'Orchestra: merge #{source_branch} into #{target_branch}'"

    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, {:exit_code, code, output}}
    end
  end

  @doc """
  Staged merge strategy: aborts with typed error on conflict instead of
  writing conflict markers to main.
  """
  def staged_merge(source_branch, target_branch \\ "main") do
    with {:ok, _} <- git_checkout(target_branch),
         {:ok, _} <- git_merge(source_branch, ["--no-ff", "-m", commit_msg(source_branch)]),
         {:ok, :no_conflict} <- Orchestra.Worktree.Conflict.detect(source_branch) do
      {:ok, :merged}
    else
      {:error, {:conflicts, files}} ->
        {:error, {:conflicts_detected, files}}

      error ->
        error
    end
  end

  defp git_checkout(branch) do
    case System.cmd("git", ["checkout", branch], stderr_to_stdout: true) do
      {_, 0} -> {:ok, branch}
      {output, _} -> {:error, {:checkout_failed, output}}
    end
  end

  defp git_merge(branch, args) do
    cmd = ["merge", branch | args]
    case System.cmd("git", cmd, stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, {:merge_failed, code, output}}
    end
  end

  defp commit_msg(source) do
    "Orchestra: merge #{source} into main via worktree isolation"
  end
end
