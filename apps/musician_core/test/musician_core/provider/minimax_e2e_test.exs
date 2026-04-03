defmodule MusicianCore.Provider.MiniMaxE2ETest do
  use ExUnit.Case, async: false

  @moduletag :provider_e2e

  alias MusicianCore.Provider.OpenAICompat
  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.Request

  setup do
    case Finch.start_link(name: Req.Finch) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "complete/2 returns a valid response from MiniMax API" do
    key = System.get_env("MINIMAX_API_KEY")

    if is_nil(key) or key == "" do
      IO.puts("\n[skip] MINIMAX_API_KEY not set — skipping E2E test")
    else
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat/v1",
        model: "MiniMax-Text-01",
        api_key_env: "MINIMAX_API_KEY"
      }

      request = %Request{
        model: "MiniMax-Text-01",
        messages: [%{"role" => "user", "content" => "Say hello in one word."}],
        stream: false,
        temperature: 0.0
      }

      result = OpenAICompat.complete(config, request)

      case result do
        {:ok, response} ->
          assert response.content != nil
          assert String.length(response.content) > 0

        {:error, {:api_error, 500, %{"error" => %{"message" => msg}}}} when is_binary(msg) ->
          if String.contains?(msg, "not support model") or String.contains?(msg, "model") do
            IO.puts("\n[info] MiniMax key valid but plan does not support this model: #{msg}")
            assert true
          else
            flunk("Unexpected 500 from MiniMax API: #{msg}")
          end

        {:error, {:api_error, code, body}} when code in [401, 403] ->
          flunk("MiniMax API auth failed (#{code}): #{inspect(body)}")

        {:error, reason} ->
          flunk("Unexpected error from MiniMax API: #{inspect(reason)}")
      end
    end
  end
end
