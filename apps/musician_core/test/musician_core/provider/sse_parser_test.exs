defmodule MusicianCore.Provider.SSEParserTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.SSEParser

  test "parse_chunk/1 decodes a single data line" do
    raw = ~s(data: {"choices":[{"delta":{"content":"hello"}}]}\n\n)
    result = SSEParser.parse_chunk(raw)
    assert [%{"choices" => [%{"delta" => %{"content" => "hello"}}]}] = result
  end

  test "parse_chunk/1 returns [] for [DONE]" do
    raw = "data: [DONE]\n\n"
    assert SSEParser.parse_chunk(raw) == []
  end

  test "parse_chunk/1 handles multiple events in one chunk" do
    raw =
      ~s(data: {"choices":[{"delta":{"content":"foo"}}]}\n\ndata: {"choices":[{"delta":{"content":"bar"}}]}\n\n)

    result = SSEParser.parse_chunk(raw)
    assert length(result) == 2
    assert Enum.at(result, 0) |> get_in(["choices", Access.at(0), "delta", "content"]) == "foo"
    assert Enum.at(result, 1) |> get_in(["choices", Access.at(0), "delta", "content"]) == "bar"
  end

  test "parse_chunk/1 handles empty string gracefully" do
    assert SSEParser.parse_chunk("") == []
  end

  test "parse_chunk/1 ignores empty lines" do
    raw = "\n\n\n"
    assert SSEParser.parse_chunk(raw) == []
  end

  test "parse_chunk/1 ignores non-data lines" do
    raw = "event: message\ndata: {\"choices\":[]}\n\n"
    result = SSEParser.parse_chunk(raw)
    assert result == [%{"choices" => []}]
  end

  test "parse_chunk/1 skips malformed JSON silently" do
    raw = "data: not-json\n\n"
    assert SSEParser.parse_chunk(raw) == []
  end
end
