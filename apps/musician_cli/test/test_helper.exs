ExUnit.start()

# Ensure Bypass (a Supervisor-based OTP app) is started for all tests.
# This must happen before any test calls Bypass.open/0.
{:ok, _} = Application.ensure_all_started(:bypass)

# ---------------------------------------------------------------------------
# Test config loader
# ---------------------------------------------------------------------------

defmodule MusicianCli.TestConfigLoader do
  @moduledoc """
  Test config loader for `MusicianCli` tests.

  Registered below as the `:test_config_loader` override.
  By default returns a safe config with a "minimax" preset (native: false).

  Tests can override the returned config per-test by setting
  `Application.put_env(:musician_core, :__test_config__, %Schema{})` before
  calling `MusicianCore.Config.Loader.load/0`.
  """

  @behaviour MusicianCore.Config.Loader.Behaviour

  @impl true
  def load do
    config = Application.get_env(:musician_core, :__test_config__) || default_config()
    {:ok, config}
  end

  @impl true
  def load(_opts) do
    opts = normalize_opts(_opts)
    global = Keyword.get(opts, :global, "")
    local = Keyword.get(opts, :local)

    # Always use musician_core's priv/fixtures for all musician_core config loading.
    # This works in CI and local environments regardless of absolute paths.
    priv = :code.priv_dir(:musician_core) |> List.to_string()
    fixture_global = Path.join([priv, "fixtures", "global_config.yaml"])
    fixture_local = Path.join([priv, "fixtures", "local_config.yaml"])

    # Use local fixtures only when test explicitly asks for them.
    # The "missing config" test passes "/nonexistent" which doesn't match,
    # so we fall through for that case.
    use_local? = local != nil and local != ""
    final_local = if use_local?, do: fixture_local, else: nil

    MusicianCore.Config.Loader.load_impl(global: fixture_global, local: final_local)
  end

  # Normalize opts to handle both list and keyword formats
  defp normalize_opts(opts) when is_list(opts), do: opts

  defp default_config do
    %MusicianCore.Config.Schema{
      default_provider: "minimax",
      providers: %{
        "minimax" => %MusicianCore.Config.Schema.ProviderConfig{
          api_base: "https://api.minimaxi.chat/v1",
          model: "MiniMax-Text-01",
          api_key_env: "MINIMAX_API_KEY",
          native: false
        }
      }
    }
  end
end

# Register TestConfigLoader as the test override for Config.Loader.
Application.put_env(:musician_core, :test_config_loader, MusicianCli.TestConfigLoader)
