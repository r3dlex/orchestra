defmodule MusicianCore.Provider.AnthropicTest do
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
  end

  describe "streaming.ex" do
    test "parse_chunk/1 extracts data lines from SSE" do
      alias MusicianCore.Provider.Streaming

      chunk = """
      data: {"choices":[{"delta":{"content":"Hello"}}]}

      data: {"choices":[{"delta":{"content":" world"},"finish_reason":"stop"}]}

      data: [DONE]
      """

      parsed = Streaming.parse_chunk(chunk)
      assert length(parsed) == 2
    end

    test "extract_delta/1 returns content from chunk" do
      alias MusicianCore.Provider.Streaming

      chunk = %{"choices" => [%{"delta" => %{"content" => "Hello"}}]}
      assert Streaming.extract_delta(chunk) == "Hello"
    end
  end
end
