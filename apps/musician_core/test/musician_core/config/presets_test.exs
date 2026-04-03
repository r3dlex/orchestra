defmodule MusicianCore.Config.PresetsTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Config.Presets

  test "all/0 returns map with 5 providers" do
    presets = Presets.all()
    assert map_size(presets) == 5
    assert Map.has_key?(presets, "minimax")
    assert Map.has_key?(presets, "claude")
    assert Map.has_key?(presets, "codex")
    assert Map.has_key?(presets, "gemini")
    assert Map.has_key?(presets, "ollama")
  end

  test "get/1 returns correct preset" do
    minimax = Presets.get("minimax")
    assert minimax.api_base == "https://api.minimax.chat/v1"
    assert minimax.model == "abab7-chat"
  end

  test "claude preset has native: true" do
    claude = Presets.get("claude")
    assert claude.native == true
  end

  test "codex preset has auth_method: :device" do
    codex = Presets.get("codex")
    assert codex.auth_method == :device
  end

  test "get/1 returns nil for unknown provider" do
    assert Presets.get("unknown") == nil
  end
end
