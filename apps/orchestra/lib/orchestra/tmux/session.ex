defmodule Orchestra.Tmux.Session do
  @moduledoc "Create and destroy tmux sessions."

  @doc """
  Creates a tmux session for the given worker name.
  Returns `{:error, {:tmux_unavailable, reason}}` if tmux is not available or too old.
  """
  def start(name) do
    case Orchestra.Tmux.Detector.available?() do
      {:error, reason} ->
        {:error, {:tmux_unavailable, reason}}

      {:ok, _path, _version} ->
        create(name)
        {:ok, name}
    end
  end

  @doc """
  Destroys a tmux session by name.
  """
  def destroy(name) do
    try do
      System.cmd("tmux", ["kill-session", "-t", name], stderr_to_stdout: true)
    rescue
      ErlangError -> :ignored
    end

    :ok
  end

  defp create(name) do
    try do
      System.cmd("tmux", ["new-session", "-d", "-s", name], stderr_to_stdout: true)
    rescue
      ErlangError -> :ignored
    end

    name
  end
end
