defmodule MusicianCore.Provider.ClaudeE2ETest do
  use ExUnit.Case, async: false

  @moduletag :provider_e2e
  @moduletag :claude_e2e

  alias MusicianCore.Provider.Anthropic
  alias MusicianCore.Config.Presets
  alias MusicianCore.Provider.Request
  import MusicianCore.E2EHelpers

  setup do: start_finch()

  test "complete/2 returns a valid response from Claude API" do
    key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(key) or key == "" do
      IO.puts("\n[skip] ANTHROPIC_API_KEY not set — skipping E2E test")
    else
      # Use preset which has the correct api_base (MiniMax Anthropic proxy) and model
      config = Presets.get("claude")

      request = %Request{
        model: config.model,
        messages: [%{"role" => "user", "content" => "Say hello in one word."}],
        stream: false,
        temperature: 0.0
      }

      result = Anthropic.complete(config, request)

      case result do
        {:ok, response} ->
          assert response.content != nil
          assert String.length(response.content) > 0
          IO.puts("\n[Claude complete] content: #{response.content}")

        {:error, :unauthorized} ->
          flunk("Claude API auth failed — check ANTHROPIC_API_KEY")

        {:error, :rate_limited} ->
          IO.puts("\n[info] Claude API rate limited — test skipped")
          assert true

        {:error, {:api_error, status, body}} when status in [401, 403] ->
          flunk("Claude API auth failed (#{status}): #{inspect(body)}")

        {:error, reason} ->
          flunk("Unexpected error from Claude API: #{inspect(reason)}")
      end
    end
  end

  test "stream/2 emits at least 1 chunk from Claude" do
    key = System.get_env("ANTHROPIC_API_KEY")

    if is_nil(key) or key == "" do
      IO.puts("\n[skip] ANTHROPIC_API_KEY not set")
    else
      config = Presets.get("claude")

      request = %Request{
        model: config.model,
        messages: [%{"role" => "user", "content" => "Say hi in one word."}],
        stream: true,
        temperature: 0.0
      }

      {:ok, stream} = Anthropic.stream(config, request)
      chunks = Enum.to_list(stream)
      IO.puts("\n[Claude streaming] #{length(chunks)} chunks received")
      assert chunks != []
    end
  end
end
