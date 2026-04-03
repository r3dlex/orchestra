defmodule MusicianCore.Provider.MiniMaxModelsE2ETest do
  use ExUnit.Case, async: false
  @moduletag :provider_e2e

  alias MusicianCore.Provider.OpenAICompat
  alias MusicianCore.Config.Schema.ProviderConfig
  import MusicianCore.E2EHelpers

  setup do: start_finch()

  test "list_models/1 returns ok or handled error from MiniMax" do
    key = System.get_env("MINIMAX_API_KEY")
    if is_nil(key) or key == "" do
      IO.puts("\n[skip] MINIMAX_API_KEY not set")
    else
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat/v1",
        model: "MiniMax-Text-01",
        api_key_env: "MINIMAX_API_KEY"
      }
      result = safe_call(fn -> OpenAICompat.list_models(config) end)
      case result do
        {:ok, models} ->
          assert is_list(models)
          IO.puts("\n[MiniMax models] #{length(models)} models available")
        {:error, {:api_error, status, _body}} when status in [404, 401, 403] ->
          IO.puts("\n[info] list_models returned #{status} — endpoint may not be available on this plan")
          assert true
        {:error, reason} ->
          flunk("Unexpected error from list_models: #{inspect(reason)}")
      end
    end
  end
end
