ExUnit.start()

# Test config loader — provides fixtures without needing real YAML files.
# Registered after module definition below.
defmodule MusicianCore.TestConfigLoader do
  @moduledoc "Loads fixture-based config for musician_core tests."

  # Always delegate to load_impl with the test fixtures.
  # __DIR__ resolves at compile time to the test_helper.exs directory.
  @fixture_global Path.join([__DIR__, "fixtures", "global_config.yaml"])
  @fixture_local Path.join([__DIR__, "fixtures", "local_config.yaml"])

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
