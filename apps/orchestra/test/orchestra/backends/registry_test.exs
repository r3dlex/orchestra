defmodule Orchestra.Backends.RegistryTest do
  use ExUnit.Case, async: true

  alias Orchestra.Backends.Registry

  test "detect/0 returns {:ok, list} or {:error, :no_backends}" do
    result = Registry.detect()
    assert match?({:ok, _}, result) or match?({:error, :no_backends}, result)
  end

  test "detect_with/1 returns {:error, :no_backends} when all paths are nil" do
    assert {:error, :no_backends} =
             Registry.detect_with(musician: nil, claude: nil, codex: nil, gemini: nil)
  end

  test "detect_with/1 returns {:ok, backends} when at least one path is non-nil" do
    assert {:ok, backends} =
             Registry.detect_with(
               musician: "/usr/bin/musician",
               claude: nil,
               codex: nil,
               gemini: nil
             )

    assert {:musician, "/usr/bin/musician"} in backends
  end
end
