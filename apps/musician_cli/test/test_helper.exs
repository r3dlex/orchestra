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
    # load/1 ignores opts — all config comes from the :__test_config__ env var
    load()
  end

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
