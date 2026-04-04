defmodule MusicianCore.Provider.ClaudeTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.{Anthropic, Request}

  describe "translate_request/1" do
    test "converts OpenAI messages format to Anthropic format" do
      req = %Request{
        model: "claude-sonnet-4-6",
        messages: [
          %{"role" => "system", "content" => "You are helpful."},
          %{"role" => "user", "content" => "Hello"}
        ]
      }

      result = Anthropic.translate_request(req)

      assert result["model"] == "claude-sonnet-4-6"
      assert result["system"] == "You are helpful."
      assert length(result["messages"]) == 1
      assert hd(result["messages"])["role"] == "user"
      assert hd(result["messages"])["content"] == "Hello"
    end

    test "request without system message has no system key" do
      req = %Request{
        model: "claude-sonnet-4-6",
        messages: [%{"role" => "user", "content" => "Hello"}]
      }

      result = Anthropic.translate_request(req)
      refute Map.has_key?(result, "system")
    end

    test "translates tools to Anthropic input_schema format" do
      tool = %{
        "type" => "function",
        "function" => %{
          "name" => "bash",
          "description" => "Run a bash command",
          "parameters" => %{"type" => "object", "properties" => %{}}
        }
      }

      req = %Request{
        model: "claude-sonnet-4-6",
        messages: [%{"role" => "user", "content" => "Hello"}],
        tools: [tool]
      }

      result = Anthropic.translate_request(req)
      assert [anthropic_tool] = result["tools"]
      assert anthropic_tool["name"] == "bash"
      assert Map.has_key?(anthropic_tool, "input_schema")
    end

    test "uses default max_tokens when not specified" do
      req = %Request{
        model: "claude-sonnet-4-6",
        messages: [%{"role" => "user", "content" => "Hello"}]
      }

      result = Anthropic.translate_request(req)
      assert result["max_tokens"] == 4096
    end

    test "passes through custom max_tokens" do
      req = %Request{
        model: "claude-sonnet-4-6",
        messages: [%{"role" => "user", "content" => "Hello"}],
        max_tokens: 100
      }

      result = Anthropic.translate_request(req)
      assert result["max_tokens"] == 100
    end
  end

  describe "translate_response/1" do
    test "extracts text content from Anthropic response" do
      body = %{
        "id" => "msg_123",
        "type" => "message",
        "content" => [%{"type" => "text", "text" => "Hello, world!"}],
        "stop_reason" => "end_turn"
      }

      result = Anthropic.translate_response(body)

      assert result.id == "msg_123"
      assert result.content == "Hello, world!"
      assert result.finish_reason == "end_turn"
    end

    test "returns nil content when content block is not text type" do
      body = %{
        "id" => "msg_123",
        "type" => "message",
        "content" => [%{"type" => "thinking", "text" => "..."}],
        "stop_reason" => "end_turn"
      }

      result = Anthropic.translate_response(body)
      assert result.content == nil
    end

    test "returns nil content when content is empty" do
      body = %{
        "id" => "msg_123",
        "type" => "message",
        "content" => [],
        "stop_reason" => "end_turn"
      }

      result = Anthropic.translate_response(body)
      assert result.content == nil
    end

    test "parses usage fields correctly" do
      body = %{
        "id" => "msg_123",
        "type" => "message",
        "content" => [%{"type" => "text", "text" => "Hello"}],
        "stop_reason" => "end_turn",
        "usage" => %{
          "input_tokens" => 10,
          "output_tokens" => 5
        }
      }

      result = Anthropic.translate_response(body)

      assert result.usage.prompt_tokens == 10
      assert result.usage.completion_tokens == 5
      assert result.usage.total_tokens == 15
    end

    test "handles nil usage" do
      body = %{
        "id" => "msg_123",
        "type" => "message",
        "content" => [%{"type" => "text", "text" => "Hello"}],
        "stop_reason" => "end_turn"
      }

      result = Anthropic.translate_response(body)
      assert result.usage == nil
    end
  end
end
