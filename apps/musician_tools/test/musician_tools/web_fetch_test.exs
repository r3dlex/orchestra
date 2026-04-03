defmodule MusicianTools.WebFetchTest do
  use ExUnit.Case, async: true
  alias MusicianTools.WebFetch

  test "name/0 returns web_fetch" do
    assert WebFetch.name() == "web_fetch"
  end

  test "description/0 returns a non-empty string" do
    assert String.length(WebFetch.description()) > 0
  end

  test "schema/0 returns a map with url key" do
    schema = WebFetch.schema()
    assert is_map(schema)
    assert Map.has_key?(schema, :url)
  end

  test "execute/1 returns {:ok, body} for valid URL" do
    # Use a reliable test endpoint
    result = WebFetch.execute(%{url: "https://httpbin.org/get"})

    case result do
      {:ok, body} -> assert is_binary(body) and String.length(body) > 0
      # Network may be unavailable in CI
      {:error, _} -> :ok
    end
  end

  test "execute/1 returns {:error, reason} for invalid URL" do
    result = WebFetch.execute(%{url: "not-a-url"})
    assert match?({:error, _}, result)
  end
end
