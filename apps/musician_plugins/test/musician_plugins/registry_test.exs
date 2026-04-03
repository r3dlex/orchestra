defmodule MusicianPlugins.RegistryTest do
  use ExUnit.Case, async: true

  alias MusicianPlugins.Registry

  test "register/2 and lookup/2 round-trip a plugin" do
    registry = Registry.new()
    registry = Registry.register(registry, :orchestra, %{module: Orchestra.Plugin, version: "1.0"})
    assert {:ok, plugin} = Registry.lookup(registry, :orchestra)
    assert plugin.module == Orchestra.Plugin
  end

  test "lookup/2 returns {:error, :not_found} for unknown plugin" do
    registry = Registry.new()
    assert {:error, :not_found} = Registry.lookup(registry, :unknown)
  end

  test "list/1 returns all registered plugins" do
    registry = Registry.new()
    registry = Registry.register(registry, :a, %{module: Foo})
    registry = Registry.register(registry, :b, %{module: Bar})
    assert length(Registry.list(registry)) == 2
  end
end
