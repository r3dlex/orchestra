defmodule Orchestra.Tmux.Commands do
  @moduledoc "Wrappers for tmux CLI commands."

  def send_keys(pane, keys) do
    "tmux send-keys -t #{pane} #{inspect(keys)} Enter"
  end

  def capture_pane(pane) do
    "tmux capture-pane -pt #{pane}"
  end
end
