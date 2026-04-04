defmodule MusicianTools.Bash do
  @moduledoc "Tool: run a bash command and return its output."

  def name, do: "bash"
  def description, do: "Execute a bash shell command and return stdout+stderr output."

  def schema do
    %{
      command: %{type: :string, description: "The shell command to run", required: true}
    }
  end

  def execute(%{command: command}) do
    case System.cmd("sh", ["-c", command], stderr_to_stdout: true) do
      {output, 0} -> {:ok, %{out: output, err: "", exit_code: 0}}
      {output, code} -> {:ok, %{out: "", err: output, exit_code: code}}
    end
  end
end
