defmodule Orchestra.Worktree.Lifecycle do
  @moduledoc "Git worktree lifecycle management."

  def create_cmd(path, branch) do
    "git worktree add #{path} -b #{branch}"
  end

  def create(path, branch) do
    case System.cmd("sh", ["-c", create_cmd(path, branch)], stderr_to_stdout: true) do
      {_, 0} -> {:ok, path}
      {output, code} -> {:error, {:exit_code, code, output}}
    end
  end

  def cleanup_cmd(path) do
    "git worktree remove #{path} --force"
  end

  def cleanup(path) do
    case System.cmd("sh", ["-c", cleanup_cmd(path)], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, code} -> {:error, {:exit_code, code, output}}
    end
  end
end
