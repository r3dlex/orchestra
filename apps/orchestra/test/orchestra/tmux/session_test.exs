defmodule Orchestra.Tmux.SessionTest do
  use ExUnit.Case, async: true
  alias Orchestra.Tmux.Session

  test "create/1 returns a session name string" do
    name = Session.create("test-session")
    assert is_binary(name)
  end

  test "destroy/1 returns :ok" do
    assert :ok = Session.destroy("test-session")
  end
end
