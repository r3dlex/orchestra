defmodule Orchestra.Tmux.SessionTest do
  use ExUnit.Case, async: true

  alias Orchestra.Tmux.Session

  describe "start/1" do
    test "returns {:error, {:tmux_unavailable, :tmux_not_found}} when tmux is absent" do
      # When tmux is not installed, Detector.available? returns :tmux_not_found
      result = Session.start("test-session")
      assert match?({:error, {:tmux_unavailable, _}}, result)
    end
  end

  describe "destroy/1" do
    test "returns :ok even when session does not exist" do
      assert :ok = Session.destroy("nonexistent-session")
    end
  end
end
