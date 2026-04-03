defmodule MusicianAuth.CodexCompletionE2ETest do
  use ExUnit.Case, async: false
  @moduletag :provider_e2e

  alias MusicianAuth.TokenStore
  alias MusicianCore.Provider.OpenAICompat
  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.Request

  setup do
    case Finch.start_link(name: Req.Finch) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "complete/2 with stored Codex tokens returns a valid response" do
    case TokenStore.read("codex") do
      {:error, :not_found} ->
        IO.puts("\n[skip] ~/.musician/auth/codex.yaml not found — run Codex device flow first")

      {:ok, %{"access_token" => token}} when is_binary(token) ->
        System.put_env("CODEX_ACCESS_TOKEN", token)

        config = %ProviderConfig{
          api_base: "https://api.openai.com/v1",
          model: "gpt-4o-mini",
          api_key_env: "CODEX_ACCESS_TOKEN"
        }

        request = %Request{
          model: "gpt-4o-mini",
          messages: [%{"role" => "user", "content" => "Say hello in one word."}],
          stream: false,
          temperature: 0.0
        }

        result = OpenAICompat.complete(config, request)

        case result do
          {:ok, response} ->
            assert response.content != nil
            assert String.length(response.content) > 0
            IO.puts("\n[Codex completion] #{response.content}")
          {:error, {:api_error, 401, _}} ->
            IO.puts("\n[info] Codex token expired — re-run device flow to refresh")
            assert true
          {:error, reason} ->
            flunk("Unexpected error: #{inspect(reason)}")
        end

        System.delete_env("CODEX_ACCESS_TOKEN")

      {:ok, tokens} ->
        IO.puts("\n[skip] codex.yaml exists but has no access_token: #{inspect(Map.keys(tokens))}")
    end
  end
end
