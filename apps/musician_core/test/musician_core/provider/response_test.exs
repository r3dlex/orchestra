defmodule MusicianCore.Provider.ResponseTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.Response

  test "from_openai/1 parses a standard completion response" do
    body = %{
      "id" => "chatcmpl-123",
      "choices" => [
        %{
          "message" => %{"role" => "assistant", "content" => "Hello!"},
          "finish_reason" => "stop"
        }
      ],
      "usage" => %{
        "prompt_tokens" => 10,
        "completion_tokens" => 5,
        "total_tokens" => 15
      }
    }

    response = Response.from_openai(body)

    assert response.id == "chatcmpl-123"
    assert response.content == "Hello!"
    assert response.finish_reason == "stop"
    assert response.usage.total_tokens == 15
  end

  test "from_openai/1 handles missing usage gracefully" do
    body = %{
      "choices" => [%{"message" => %{"content" => "Hi"}, "finish_reason" => "stop"}]
    }

    response = Response.from_openai(body)
    assert response.content == "Hi"
    assert response.usage == nil
  end
end
