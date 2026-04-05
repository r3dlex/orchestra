ExUnit.start()

# Test config loader — provides fixtures without needing real YAML files.
# Registered after module definition below.
defmodule MusicianCore.TestConfigLoader do
  @moduledoc "Loads fixture-based config for musician_core tests."

  @behaviour MusicianCore.Config.Loader.Behaviour

  @impl true
  def load(opts) do
    opts = normalize_opts(opts)
    global = Keyword.get(opts, :global, "")
    local = Keyword.get(opts, :local)

    fixture_global = fixture_path("global_config.yaml")
    fixture_local = fixture_path("local_config.yaml")

    # Determine effective global path:
    # - if explicit path exists, use it
    # - otherwise use fixture
    final_global =
      if global != "" and File.exists?(global) do
        global
      else
        fixture_global
      end

    # Determine effective local path:
    # - if local is explicitly nil, pass nil (no local override)
    # - if explicit local path exists, use it
    # - if local is provided but doesn't exist, use fixture
    # - if local is not provided at all, use fixture
    final_local =
      cond do
        is_nil(local) ->
          nil

        local != "" and File.exists?(local) ->
          local

        true ->
          fixture_local
      end

    MusicianCore.Config.Loader.load_impl(global: final_global, local: final_local)
  end

  defp normalize_opts(opts) when is_list(opts), do: opts
  defp normalize_opts(_), do: []

  defp fixture_path(name) do
    priv = :code.priv_dir(:musician_core) |> List.to_string()
    Path.join([priv, "fixtures", name])
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
