defmodule MusicianCore.Provider.RequestTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.Request

  test "to_map/1 includes required fields" do
    req = %Request{
      model: "abab7-chat",
      messages: [%{"role" => "user", "content" => "Hello"}]
    }

    result = Request.to_map(req)

    assert result["model"] == "abab7-chat"
    assert result["messages"] == [%{"role" => "user", "content" => "Hello"}]
    assert result["stream"] == false
  end

  test "to_map/1 excludes empty tools" do
    req = %Request{model: "test", messages: [], tools: []}
    result = Request.to_map(req)
    refute Map.has_key?(result, "tools")
  end

  test "to_map/1 includes tools when present" do
    tool = %{"type" => "function", "function" => %{"name" => "bash"}}
    req = %Request{model: "test", messages: [], tools: [tool]}
    result = Request.to_map(req)
    assert result["tools"] == [tool]
  end
end
