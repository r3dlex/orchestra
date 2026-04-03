defmodule Orchestra.Backends.ClaudeTest do
  use ExUnit.Case, async: true
  alias Orchestra.Backends.Claude

  test "run/3 returns string containing 'claude'" do
    cmd = Claude.run("w1", {:claude, nil}, %{task: "do something", worktree_path: "/tmp/wt"})
    assert is_binary(cmd)
    assert String.contains?(cmd, "claude")
  end
end
