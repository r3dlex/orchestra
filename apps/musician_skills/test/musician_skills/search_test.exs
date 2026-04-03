defmodule MusicianSkills.SearchTest do
  use ExUnit.Case, async: true

  alias MusicianSkills.Search

  @skills [
    %{name: "debug-tests", description: "Debug failing tests", triggers: ["test.*fail", "debug"]},
    %{name: "refactor", description: "Refactor code for clarity", triggers: ["refactor"]},
    %{name: "commit", description: "Create a git commit", triggers: ["commit", "git.*commit"]}
  ]

  test "find_by_name/2 returns skill matching name" do
    result = Search.find_by_name(@skills, "debug-tests")
    assert result.name == "debug-tests"
  end

  test "find_by_name/2 returns nil for unknown name" do
    assert Search.find_by_name(@skills, "unknown") == nil
  end

  test "find_by_trigger/2 returns skills matching trigger pattern" do
    results = Search.find_by_trigger(@skills, "debug")
    assert Enum.any?(results, &(&1.name == "debug-tests"))
  end

  test "find_by_trigger/2 returns empty list for no match" do
    results = Search.find_by_trigger(@skills, "zzz_no_match_zzz")
    assert results == []
  end
end
