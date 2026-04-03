defmodule MusicianSession.ResumeTest do
  use ExUnit.Case, async: true

  alias MusicianSession.Resume

  @sessions [
    %{"session_id" => "abc-123", "prompt_summary" => "session one"},
    %{"session_id" => "def-456", "prompt_summary" => "session two"}
  ]

  test "find_by_id/2 returns matching session" do
    assert {:ok, session} = Resume.find_by_id(@sessions, "abc-123")
    assert session["prompt_summary"] == "session one"
  end

  test "find_by_id/2 returns {:error, :not_found} for unknown id" do
    assert {:error, :not_found} = Resume.find_by_id(@sessions, "unknown-id")
  end
end
