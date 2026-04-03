defmodule Orchestra.Backends.GeminiTest do
  use ExUnit.Case, async: true
  alias Orchestra.Backends.Gemini

  test "run/3 returns string containing 'gemini'" do
    cmd = Gemini.run("w1", {:gemini, nil}, %{task: "do something", worktree_path: "/tmp/wt"})
    assert is_binary(cmd)
    assert String.contains?(cmd, "gemini")
  end
end
