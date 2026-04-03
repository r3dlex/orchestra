defmodule MusicianMemory.TypesTest do
  use ExUnit.Case, async: true

  alias MusicianMemory.Types

  test "@types contains the 4 memory types" do
    assert :user in Types.types()
    assert :feedback in Types.types()
    assert :project in Types.types()
    assert :reference in Types.types()
  end

  test "@scopes contains private and team" do
    assert :private in Types.scopes()
    assert :team in Types.scopes()
  end

  test "valid_type?/1 returns true for :user" do
    assert Types.valid_type?(:user)
  end

  test "valid_type?/1 returns false for :unknown" do
    refute Types.valid_type?(:unknown)
  end

  test "valid_scope?/1 returns true for :private" do
    assert Types.valid_scope?(:private)
  end
end
