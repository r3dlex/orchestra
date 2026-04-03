defmodule MusicianCore.Config.LoaderTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Config.{Loader, Schema}

  @fixtures_dir Path.join([__DIR__, "..", "..", "fixtures"])
  @global_fixture Path.join(@fixtures_dir, "global_config.yaml")
  @local_fixture Path.join(@fixtures_dir, "local_config.yaml")

  describe "load/1 with fixture files" do
    test "loads global config and returns correct struct" do
      {:ok, config} = Loader.load(global: @global_fixture, local: nil)

      assert %Schema{} = config
      assert config.default_provider == "minimax"
      assert config.tui.theme == "solarized"
      assert map_size(config.providers) == 2
    end

    test "local config values override global config values" do
      {:ok, config} = Loader.load(global: @global_fixture, local: @local_fixture)

      assert config.default_provider == "claude"
      assert config.tui.theme == "dark"
      assert config.tui.vim_mode == true
    end

    test "non-overridden global values are preserved after merge" do
      {:ok, config} = Loader.load(global: @global_fixture, local: @local_fixture)

      assert config.memory.nudge_interval_minutes == 30
      assert map_size(config.providers) == 2
    end

    test "missing config file returns defaults" do
      {:ok, config} = Loader.load(global: "/nonexistent/path.yaml", local: nil)

      assert %Schema{} = config
      assert config.default_provider == "minimax"
    end

    test "native flag is parsed correctly for claude provider" do
      {:ok, config} = Loader.load(global: @global_fixture, local: nil)

      claude = config.providers["claude"]
      assert claude.native == true
    end
  end

  describe "deep_merge" do
    test "load/0 does not crash (no config files present in test env)" do
      # load/0 uses ~/.musician/config.yaml which may not exist — should return defaults
      assert {:ok, %Schema{}} = Loader.load()
    end
  end
end
