defmodule Orchestra.Tmux.PaneTest do
  use ExUnit.Case, async: true
  alias Orchestra.Tmux.Pane

  describe "create/1" do
    test "returns pane name formatted as omc-worker-{worker_id}" do
      assert Pane.create("1") == "omc-worker-1"
      assert Pane.create("abc-123") == "omc-worker-abc-123"
      assert Pane.create("worker-42") == "omc-worker-worker-42"
    end
  end

  describe "send_keys/2" do
    test "delegates to Tmux.Commands and formats the pane name into the command" do
      pane = "omc-worker-1"
      keys = "echo hello"

      # Verify Tmux.Commands.send_keys/2 produces a well-formed tmux command
      cmd = Orchestra.Tmux.Commands.send_keys(pane, keys)
      assert cmd =~ "tmux send-keys"
      assert cmd =~ pane
      assert cmd =~ keys
    end
  end

  describe "capture/1" do
    test "delegates to Tmux.Commands and formats the pane name into the command" do
      pane = "omc-worker-1"

      cmd = Orchestra.Tmux.Commands.capture_pane(pane)
      assert cmd =~ "tmux capture-pane"
      assert cmd =~ pane
    end
  end
end
