defmodule Orchestra.Tmux.Session do
  @moduledoc "Create and destroy tmux sessions."

  def create(name) do
    try do
      System.cmd("tmux", ["new-session", "-d", "-s", name], stderr_to_stdout: true)
    rescue
      ErlangError -> :ignored
    end

    name
  end

  def destroy(name) do
    try do
      System.cmd("tmux", ["kill-session", "-t", name], stderr_to_stdout: true)
    rescue
      ErlangError -> :ignored
    end

    :ok
  end
end
