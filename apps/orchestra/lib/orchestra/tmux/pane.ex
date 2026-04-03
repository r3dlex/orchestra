defmodule Orchestra.Tmux.Pane do
  @moduledoc "Manage tmux panes."

  def create(worker_id) do
    "omc-worker-#{worker_id}"
  end

  def send_keys(pane, keys) do
    Orchestra.Tmux.Commands.send_keys(pane, keys)
    |> run_cmd()
  end

  def capture(pane) do
    Orchestra.Tmux.Commands.capture_pane(pane)
    |> run_cmd()
  end

  defp run_cmd(cmd) do
    case System.cmd("sh", ["-c", cmd], stderr_to_stdout: true) do
      {output, 0} -> {:ok, output}
      {output, code} -> {:error, {:exit_code, code, output}}
    end
  end
end
