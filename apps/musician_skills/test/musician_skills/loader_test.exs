defmodule MusicianSkills.LoaderTest do
  use ExUnit.Case, async: true

  alias MusicianSkills.Loader

  @fixture_dir System.tmp_dir!() |> Path.join("musician_skills_test_#{:rand.uniform(100_000)}")
  @fixture_skill Path.join(@fixture_dir, "test_skill")

  setup do
    File.mkdir_p!(@fixture_skill)

    skill_md = """
    ---
    name: test-skill
    description: A test skill for unit testing
    version: "1.0"
    triggers:
      - "test.*skill"
    ---

    When invoked, do the following steps.
    """

    File.write!(Path.join(@fixture_skill, "SKILL.md"), skill_md)
    on_exit(fn -> File.rm_rf(@fixture_dir) end)
    {:ok, skill_path: @fixture_skill}
  end

  test "load/1 parses SKILL.md name field", %{skill_path: path} do
    assert {:ok, skill} = Loader.load(path)
    assert skill.name == "test-skill"
  end

  test "load/1 parses SKILL.md description field", %{skill_path: path} do
    assert {:ok, skill} = Loader.load(path)
    assert skill.description == "A test skill for unit testing"
  end

  test "load/1 parses SKILL.md body", %{skill_path: path} do
    assert {:ok, skill} = Loader.load(path)
    assert String.contains?(skill.body, "When invoked")
  end

  test "load/1 parses triggers list", %{skill_path: path} do
    assert {:ok, skill} = Loader.load(path)
    assert is_list(skill.triggers)
    assert "test.*skill" in skill.triggers
  end

  test "load/1 returns {:error, :not_found} for missing path" do
    assert {:error, :not_found} = Loader.load("/nonexistent/path/skill")
  end
end
