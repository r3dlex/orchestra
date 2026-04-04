defmodule Orchestra.Worktree.Conflict do
  @moduledoc "Detect and report merge conflicts in a worktree branch."

  @doc """
  Detects if there are active merge conflicts for a given branch.
  Returns {:ok, :no_conflict} or {:error, {:conflicts, files}}.
  """
  def detect(branch) do
    case System.cmd("git", ["merge-head", branch], stderr_to_stdout: true) do
      {_, 128} ->
        {:ok, :no_conflict}

      {output, 0} ->
        parse_conflict_paths(output)
    end
  end

  @doc """
  Lists conflicted files in a worktree by running git diff with the U filter.
  """
  def list_conflicted_files(worktree_path) do
    cmd = "git diff --name-only --diff-filter=U"

    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true, cwd: worktree_path) do
      {output, 0} ->
        files = output |> String.split("\n", trim: true)
        {:ok, files}

      {_, _} ->
        {:ok, []}
    end
  end

  defp parse_conflict_paths(output) do
    files =
      Regex.scan(~r/^\+\+\+ b\/(.+)$/m, output, capture: :all_but_first)
      |> List.flatten()

    {:error, {:conflicts, files}}
  end
end
