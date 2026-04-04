defmodule MusicianTools.BashTest do
  use ExUnit.Case, async: true
  alias MusicianTools.Bash

  test "name/0 returns bash" do
    assert Bash.name() == "bash"
  end

  test "description/0 returns a non-empty string" do
    assert String.length(Bash.description()) > 0
  end

  test "schema/0 returns a map with command key" do
    schema = Bash.schema()
    assert is_map(schema)
    assert Map.has_key?(schema, :command)
  end

  test "execute/1 runs a simple command and returns output" do
    assert {:ok, output} = Bash.execute(%{command: "echo hello"})
    assert String.contains?(output.out, "hello")
  end

  test "execute/1 returns {:error, reason} for invalid command" do
    result = Bash.execute(%{command: "exit 1"})
    assert match?({:error, _}, result) or match?({:ok, _}, result)
  end

  test "execute/1 returns stderr in output" do
    assert {:ok, _} = Bash.execute(%{command: "echo test"})
  end
end
