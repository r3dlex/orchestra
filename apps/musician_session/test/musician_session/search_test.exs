defmodule MusicianSession.SearchTest do
  use ExUnit.Case, async: true

  alias MusicianSession.Search

  @sessions [
    %{
      "session_id" => "s1",
      "timestamp" => "2026-01-01T10:00:00Z",
      "prompt_summary" => "debugged auth module",
      "provider" => "minimax"
    },
    %{
      "session_id" => "s2",
      "timestamp" => "2026-02-15T10:00:00Z",
      "prompt_summary" => "refactored config loader",
      "provider" => "claude"
    },
    %{
      "session_id" => "s3",
      "timestamp" => "2026-03-01T10:00:00Z",
      "prompt_summary" => "added minimax provider tests",
      "provider" => "minimax"
    }
  ]

  test "by_keyword/2 returns sessions matching keyword in prompt_summary" do
    results = Search.by_keyword(@sessions, "auth")
    assert length(results) == 1
    assert hd(results)["session_id"] == "s1"
  end

  test "by_keyword/2 is case-insensitive" do
    results = Search.by_keyword(@sessions, "CONFIG")
    assert length(results) == 1
    assert hd(results)["session_id"] == "s2"
  end

  test "by_keyword/2 returns empty list for no match" do
    assert Search.by_keyword(@sessions, "zzz_no_match") == []
  end

  test "by_time_range/3 returns sessions within the given range" do
    results = Search.by_time_range(@sessions, "2026-01-01T00:00:00Z", "2026-02-28T23:59:59Z")
    assert length(results) == 2
    ids = Enum.map(results, & &1["session_id"])
    assert "s1" in ids
    assert "s2" in ids
  end

  test "by_time_range/3 returns empty list when no sessions match" do
    results = Search.by_time_range(@sessions, "2025-01-01T00:00:00Z", "2025-12-31T23:59:59Z")
    assert results == []
  end
end
