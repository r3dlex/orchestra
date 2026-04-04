defmodule MusicianCli.Cli.StreamTest do
  @moduledoc """
  Tests for the streaming code paths in run_prompt/1.

  Rather than testing the full CLI (which has complex IO-capture interactions
  with the streaming Task), we test the individual pieces:
  - OpenAICompat.stream/2 with a Bypass mock — exercises the non-native stream path
  - Anthropic.stream/2 with a Bypass mock — exercises the native stream path
  - run_prompt/1 error path (unknown provider)
  """

  use ExUnit.Case, async: false

  alias MusicianCore.Provider.{OpenAICompat, Anthropic}
  alias MusicianCore.Config.Schema
  alias MusicianCore.Provider.Request
  alias MusicianCli.Cli

  setup do
    case Finch.start_link(name: Req.Finch) do
      {:ok, pid} ->
        Process.unlink(pid)
        :ok

      {:error, {:already_started, pid}} ->
        Process.unlink(pid)
        :ok
    end
  end

  # ---------------------------------------------------------------------------
  # OpenAICompat.stream/2 — non-native stream path (minimax, ollama, etc.)
  # ---------------------------------------------------------------------------

  describe "OpenAICompat.stream/2" do
    test "yields SSE chunks as maps with choices/delta/content and IO-writes content" do
      bypass = Bypass.open()

      config = %Schema.ProviderConfig{
        api_base: "http://localhost:#{bypass.port}/v1",
        model: "MiniMax-Text-01",
        api_key_env: "TEST_API_KEY",
        native: false
      }

      request = %Request{
        model: "MiniMax-Text-01",
        messages: [%{"role" => "user", "content" => "say hi"}],
        stream: true,
        temperature: 0.0
      }

      Bypass.expect(bypass, fn conn ->
        body = "data: {\"choices\":[{\"delta\":{\"content\":\"Hi!\"}}]}\ndata: [DONE]\n"
        Plug.Conn.send_resp(conn, 200, body)
      end)

      {:ok, stream} = OpenAICompat.stream(config, request)

      # IO.write/1 in Stream.each runs in the same process as Enum.to_list/1,
      # so CaptureIO can intercept it.
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          stream
          |> Stream.each(fn chunk ->
            content = get_in(chunk, ["choices", Access.at(0), "delta", "content"]) || ""
            IO.write(content)
          end)
          |> Stream.run()
        end)

      assert output == "Hi!"

      # Also verify the raw chunk data
      {:ok, stream2} = OpenAICompat.stream(config, request)
      chunks = Enum.to_list(stream2)
      assert length(chunks) == 1
      assert get_in(hd(chunks), ["choices", Access.at(0), "delta", "content"]) == "Hi!"
    end

    test "yields multiple SSE chunks and concatenates IO output" do
      bypass = Bypass.open()

      config = %Schema.ProviderConfig{
        api_base: "http://localhost:#{bypass.port}/v1",
        model: "MiniMax-Text-01",
        api_key_env: "TEST_API_KEY",
        native: false
      }

      request = %Request{
        model: "MiniMax-Text-01",
        messages: [%{"role" => "user", "content" => "count"}],
        stream: true
      }

      Bypass.expect(bypass, fn conn ->
        body =
          "data: {\"choices\":[{\"delta\":{\"content\":\"One\"}}]}\ndata: {\"choices\":[{\"delta\":{\"content\":\"Two\"}}]}\ndata: [DONE]\n"

        Plug.Conn.send_resp(conn, 200, body)
      end)

      {:ok, stream} = OpenAICompat.stream(config, request)

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          stream
          |> Stream.each(fn chunk ->
            content = get_in(chunk, ["choices", Access.at(0), "delta", "content"]) || ""
            IO.write(content)
          end)
          |> Stream.run()
        end)

      assert output == "OneTwo"

      # Also verify raw chunk data
      {:ok, stream2} = OpenAICompat.stream(config, request)
      chunks = Enum.to_list(stream2)
      assert length(chunks) == 2
      assert get_in(Enum.at(chunks, 0), ["choices", Access.at(0), "delta", "content"]) == "One"
      assert get_in(Enum.at(chunks, 1), ["choices", Access.at(0), "delta", "content"]) == "Two"
    end
  end

  # ---------------------------------------------------------------------------
  # Anthropic.stream/2 — native stream path (claude)
  # ---------------------------------------------------------------------------

  describe "Anthropic.stream/2" do
    test "yields SSE chunks with content_block_delta events" do
      bypass = Bypass.open()

      config = %Schema.ProviderConfig{
        api_base: "http://localhost:#{bypass.port}/v1",
        model: "claude-sonnet-4-20250514",
        api_key_env: "TEST_API_KEY",
        native: true
      }

      request = %Request{
        model: "claude-sonnet-4-20250514",
        messages: [%{"role" => "user", "content" => "say hi"}],
        stream: true
      }

      # Anthropic uses data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"..."}}
      Bypass.expect(bypass, fn conn ->
        body =
          "data: {\"type\":\"content_block_delta\",\"index\":0,\"delta\":{\"type\":\"text_delta\",\"text\":\"Hi from Claude!\"}}\ndata: [DONE]\n"

        Plug.Conn.send_resp(conn, 200, body)
      end)

      {:ok, stream} = Anthropic.stream(config, request)
      chunks = Enum.to_list(stream)

      assert length(chunks) == 1

      assert get_in(hd(chunks), ["choices", Access.at(0), "delta", "content"]) ==
               "Hi from Claude!"
    end
  end

  # ---------------------------------------------------------------------------
  # run_prompt/1 error path — unknown provider
  # ---------------------------------------------------------------------------

  describe "run_prompt/1 — unknown provider error" do
    test "load/0 returns error for unknown provider" do
      # Test that the TestConfigLoader correctly returns a config with only "minimax".
      {:ok, config} = MusicianCore.Config.Loader.load()
      provider_name = "nonexistent"
      provider_config = Map.get(config.providers, provider_name)

      assert is_nil(provider_config)
      assert config.default_provider == "minimax"
    end

    test "Cli.main/1 with --prompt and unknown provider prints error via meck" do
      unknown_config = %Schema{
        default_provider: "minimax",
        providers: %{
          "minimax" => %Schema.ProviderConfig{
            api_base: "http://localhost:9999/v1",
            model: "x",
            api_key_env: "FOO",
            native: false
          }
        }
      }

      Application.put_env(:musician_core, :__test_config__, unknown_config)
      on_exit(fn -> Application.delete_env(:musician_core, :__test_config__) end)

      # Mock System.halt/1 so ExUnit's test process survives the error path.
      :meck.new(System, [:unstick, :passthrough])
      :meck.expect(System, :halt, 1, :ok)

      on_exit(fn ->
        try do
          :meck.unload(System)
        catch
          :error, _ -> :ok
        end
      end)

      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--prompt", "hi", "--provider", "nonexistent"])
        end)

      assert output =~ "Error: unknown provider 'nonexistent'"
      assert :meck.called(System, :halt, [1])
    end
  end
end
