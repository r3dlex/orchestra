defmodule Orchestra.CommandsTest do
  use ExUnit.Case, async: true

  alias Orchestra.Commands

  test "list/0 returns a list of command definitions" do
    commands = Commands.list()
    assert is_list(commands)
    assert commands != []
  end

  test "each command has a name and description" do
    Enum.each(Commands.list(), fn cmd ->
      assert Map.has_key?(cmd, :name)
      assert Map.has_key?(cmd, :description)
    end)
  end
end
