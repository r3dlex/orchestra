defmodule Orchestra.Backends.MusicianTest do
  use ExUnit.Case, async: true
  alias Orchestra.Backends.Musician

  test "run/3 returns a string containing 'musician --provider'" do
    cmd =
      Musician.run("worker-1", {:musician, "minimax"}, %{task: "hello", worktree_path: "/tmp/wt"})

    assert is_binary(cmd)
    assert String.contains?(cmd, "musician")
    assert String.contains?(cmd, "--provider")
    assert String.contains?(cmd, "minimax")
  end

  test "run/3 includes the worktree path" do
    cmd =
      Musician.run("w1", {:musician, "claude"}, %{task: "task", worktree_path: "/tmp/test_wt"})

    assert String.contains?(cmd, "/tmp/test_wt")
  end
end
