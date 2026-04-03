defmodule MusicianCore.Provider.MiniMaxStreamingE2ETest do
  use ExUnit.Case, async: false
  @moduletag :provider_e2e

  alias MusicianCore.Provider.OpenAICompat
  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.Request
  import MusicianCore.E2EHelpers

  setup do: start_finch()

  test "stream/2 emits at least 1 chunk from MiniMax" do
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
        messages: [%{"role" => "user", "content" => "Say hi in one word."}],
        stream: true,
        temperature: 0.0
      }
      {:ok, stream} = OpenAICompat.stream(config, request)
      chunks = Enum.to_list(stream)
      IO.puts("\n[MiniMax streaming] #{length(chunks)} chunks received")
      assert length(chunks) >= 1
    end
  end
end
