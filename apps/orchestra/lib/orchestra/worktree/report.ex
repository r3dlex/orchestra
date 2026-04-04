defmodule Orchestra.Worktree.Report do
  @moduledoc "Produce a summary of all Orchestra-managed worktrees."

  @doc """
  Returns {:ok, [report]} for all omc-worker-* directories in worktrees_dir,
  where each report includes name, path, branch, and status (:clean or {:dirty, lines}).
  """
  def summary(worktrees_dir) do
    with {:ok, dirs} <- File.ls(worktrees_dir) do
      reports =
        dirs
        |> Enum.filter(&String.starts_with?(&1, "omc-worker-"))
        |> Enum.map(&build_report(&1, worktrees_dir))

      {:ok, reports}
    end
  end

  defp build_report(name, base_dir) do
    path = Path.join(base_dir, name)
    branch = String.replace_prefix(name, "omc-worker-", "")

    %{name: name, path: path, branch: branch, status: status(path)}
  end

  defp status(path) do
    case System.cmd("git", ["status", "--porcelain"], stderr_to_stdout: true, cwd: path) do
      {"", 0} -> :clean
      {output, _} -> {:dirty, String.split(output, "\n", trim: true)}
    end
  end
end
