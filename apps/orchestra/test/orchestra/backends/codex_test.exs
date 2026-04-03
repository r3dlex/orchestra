defmodule Orchestra.Backends.CodexTest do
  use ExUnit.Case, async: true
  alias Orchestra.Backends.Codex

  test "run/3 returns string containing 'codex'" do
    cmd = Codex.run("w1", {:codex, nil}, %{task: "do something", worktree_path: "/tmp/wt"})
    assert is_binary(cmd)
    assert String.contains?(cmd, "codex")
  end
end
