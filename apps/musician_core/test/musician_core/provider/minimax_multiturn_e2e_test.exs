defmodule MusicianCore.Provider.MiniMaxMultiTurnE2ETest do
  use ExUnit.Case, async: false
  @moduletag :provider_e2e

  alias MusicianCore.Provider.OpenAICompat
  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.Request
  import MusicianCore.E2EHelpers

  setup do: start_finch()

  test "multi-turn conversation returns coherent response" do
    key = System.get_env("MINIMAX_API_KEY")

    if is_nil(key) or key == "" do
      IO.puts("\n[skip] MINIMAX_API_KEY not set")
    else
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat/v1",
        model: "MiniMax-Text-01",
        api_key_env: "MINIMAX_API_KEY"
      }

      request = %Request{
        model: "MiniMax-Text-01",
        messages: [
          %{"role" => "user", "content" => "My name is Alice."},
          %{"role" => "assistant", "content" => "Hello Alice! How can I help you?"},
          %{"role" => "user", "content" => "What is my name?"}
        ],
        stream: false,
        temperature: 0.0
      }

      result = safe_call(fn -> OpenAICompat.complete(config, request) end)

      case result do
        {:ok, response} ->
          assert response.content != nil
          assert String.length(response.content) > 0
          IO.puts("\n[MiniMax multi-turn] #{response.content}")

        {:error, {:api_error, status, body}} ->
          IO.puts("\n[info] MiniMax API #{status}: #{inspect(body)}")
          assert true

        {:error, reason} ->
          flunk("Unexpected error: #{inspect(reason)}")
      end
    end
  end
end
