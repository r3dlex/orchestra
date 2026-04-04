ExUnit.start()

# Test config loader — provides fixtures without needing real YAML files.
# Registered after module definition below.
defmodule MusicianCore.TestConfigLoader do
  @moduledoc "Loads fixture-based config for musician_core tests."

  # Use __DIR__ to locate fixtures relative to test_helper.exs location.
  # This works whether tests run from musician_core's own context or
  # from musician_cli umbrella context in CI.
  @fixture_dir Path.join([__DIR__, "fixtures"])
  @fixture_global Path.join(@fixture_dir, "global_config.yaml")
  @fixture_local Path.join(@fixture_dir, "local_config.yaml")

  # Loads config based on opts:
  #   - global fixture path + no local → global fixture only
  #   - global fixture path + local fixture path → merged global+local fixtures
  #   - anything else → {:error, :fall_through} to use real loader
  def load(opts) do
    global = Keyword.get(opts, :global)
    local = Keyword.get(opts, :local)

    cond do
      global == @fixture_global and is_nil(local) ->
        MusicianCore.Config.Loader.load_impl(global: @fixture_global, local: nil)

      global == @fixture_global and local == @fixture_local ->
        MusicianCore.Config.Loader.load_impl(global: @fixture_global, local: @fixture_local)

      true ->
        {:error, :fall_through}
    end
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
