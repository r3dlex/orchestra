defmodule Orchestra.Worktree.LifecycleTest do
  use ExUnit.Case, async: true
  alias Orchestra.Worktree.Lifecycle

  test "create/2 returns a git command string" do
    cmd = Lifecycle.create_cmd("/tmp/worktrees/worker-1", "omc-worker-1")
    assert String.contains?(cmd, "git worktree add")
    assert String.contains?(cmd, "/tmp/worktrees/worker-1")
    assert String.contains?(cmd, "omc-worker-1")
  end

  test "cleanup/1 returns a git command string" do
    cmd = Lifecycle.cleanup_cmd("/tmp/worktrees/worker-1")
    assert String.contains?(cmd, "git worktree remove")
    assert String.contains?(cmd, "/tmp/worktrees/worker-1")
  end
end
