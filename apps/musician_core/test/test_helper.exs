ExUnit.start()

# Test config loader — provides fixtures without needing real YAML files.
# Registered after module definition below.
defmodule MusicianCore.TestConfigLoader do
  @moduledoc "Loads fixture-based config for musician_core tests."

  # Always use test fixtures regardless of what paths are passed.
  # This avoids fragile path comparison that can fail across different
  # build environments and code paths.
  def load(opts) do
    fixture_global = fixture_path("global_config.yaml")
    fixture_local = fixture_path("local_config.yaml")
    MusicianCore.Config.Loader.load_impl(global: fixture_global, local: nil)
  end

  defp fixture_path(name) do
    # Use Application.app_dir to get the musician_core app root directory.
    # This works in all contexts including umbrella builds and CI environments.
    Path.join([Application.app_dir(:musician_core), "test", "fixtures", name])
  end
end

Application.put_env(:musician_core, :test_config_loader, MusicianCore.TestConfigLoader)

Mox.defmock(MusicianCore.HTTPMock, for: MusicianCore.HTTP)
Mox.defmock(MusicianCore.TokenStoreMock, for: MusicianCore.TokenStore)

# Start the Mox GenServer for Mox 1.2.0.
# Returns {:ok, pid} or :ignore (already started).
case Mox.start_link_ownership() do
  {:ok, _} -> :ok
  :ignore -> :ok
  other -> raise "Mox.start_link_ownership failed: #{inspect(other)}"
end
