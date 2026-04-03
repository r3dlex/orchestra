defmodule Orchestra.Tmux.CommandsTest do
  use ExUnit.Case, async: true
  alias Orchestra.Tmux.Commands

  test "send_keys/2 returns expected tmux command string" do
    cmd = Commands.send_keys("omc-session:pane-1", "echo hello")
    assert String.contains?(cmd, "tmux send-keys")
    assert String.contains?(cmd, "omc-session:pane-1")
    assert String.contains?(cmd, "echo hello")
  end

  test "capture_pane/1 returns expected tmux command string" do
    cmd = Commands.capture_pane("omc-session:pane-1")
    assert String.contains?(cmd, "tmux capture-pane")
    assert String.contains?(cmd, "omc-session:pane-1")
  end
end
