defmodule Orchestra.PluginTest do
  use ExUnit.Case, async: true
  alias Orchestra.Plugin

  describe "MusicianPlugins.Api behaviour callbacks" do
    test "on_load/1 returns :ok" do
      assert Plugin.on_load(%{}) == :ok
      assert Plugin.on_load(%{"foo" => "bar"}) == :ok
    end

    test "on_command/2 returns :handled for Orchestra subcommands" do
      assert Plugin.on_command("/orchestra status", %{}) == :handled
      assert Plugin.on_command("/orchestra status all", %{}) == :handled
      assert Plugin.on_command("/orchestra list", %{}) == :handled
    end

    test "on_command/2 returns :passthrough for non-Orchestra commands" do
      assert Plugin.on_command("/help", %{}) == :passthrough
      assert Plugin.on_command("/echo hello", %{}) == :passthrough
      assert Plugin.on_command("plain text message", %{}) == :passthrough
    end

    test "on_message/1 returns :passthrough" do
      assert Plugin.on_message(%{}) == :passthrough
      assert Plugin.on_message(%{"content" => "hello"}) == :passthrough
      assert Plugin.on_message(%{"role" => "user", "content" => "test"}) == :passthrough
    end
  end

  describe "implements MusicianPlugins.Api behaviour" do
    test "all required callbacks are defined and callable" do
      # Verify callbacks are callable (proves they exist)
      assert Plugin.on_load(%{}) == :ok
      assert Plugin.on_load(%{"foo" => "bar"}) == :ok
      assert Plugin.on_command("/orchestra test", %{}) == :handled
      assert Plugin.on_message(%{"foo" => "bar"}) == :passthrough
    end
  end
end
