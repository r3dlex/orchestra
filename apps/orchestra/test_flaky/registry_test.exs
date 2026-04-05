defmodule Orchestra.Backends.RegistryTest do
  use ExUnit.Case, async: true

  alias Orchestra.Backends.Registry

  describe "detect/0" do
    test "returns {:ok, list} or {:error, :no_backends}" do
      result = Registry.detect()
      assert match?({:ok, _}, result) or match?({:error, :no_backends}, result)
    end
  end

  describe "detect_with/1" do
    test "returns {:error, :no_backends} when all paths are nil" do
      assert {:error, :no_backends} =
               Registry.detect_with(musician: nil, claude: nil, codex: nil, gemini: nil)
    end

    test "returns {:ok, backends} when at least one path is non-nil" do
      assert {:ok, backends} =
               Registry.detect_with(
                 musician: "/usr/bin/musician",
                 claude: nil,
                 codex: nil,
                 gemini: nil
               )

      assert {:musician, "/usr/bin/musician"} in backends
    end

    test "excludes backends not in enabled_backends config" do
      Application.put_env(:orchestra, :enabled_backends, [:musician])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      assert {:ok, backends} =
               Registry.detect_with(
                 musician: "/usr/bin/musician",
                 claude: "/usr/bin/claude",
                 codex: nil,
                 gemini: nil
               )

      assert backends == [musician: "/usr/bin/musician"]
    end

    test "returns {:error, :no_backends} when all found backends are disabled" do
      Application.put_env(:orchestra, :enabled_backends, [:not_a_backend])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      assert {:error, :no_backends} =
               Registry.detect_with(
                 musician: "/usr/bin/musician",
                 claude: nil,
                 codex: nil,
                 gemini: nil
               )
    end
  end

  describe "preferred/0" do
    test "returns {:ok, musician} when musician is detected" do
      Application.put_env(:orchestra, :enabled_backends, [:musician, :claude])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      result = Registry.preferred()

      assert match?({:ok, {_, _}}, result)
      {name, _path} = elem(result, 1)
      assert name == :musician
    end

    test "returns first available when musician is not in enabled_backends" do
      Application.put_env(:orchestra, :enabled_backends, [:claude])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      result = Registry.preferred()

      case result do
        {:ok, {name, _path}} ->
          assert name == :claude

        {:error, :no_backends} ->
          # No backends available — also valid
          assert true
      end
    end
  end
end
