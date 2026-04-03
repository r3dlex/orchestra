defmodule MusicianSkills.CreatorTest do
  use ExUnit.Case, async: true

  alias MusicianSkills.Creator

  @tmp_dir System.tmp_dir!() |> Path.join("musician_creator_test_#{:rand.uniform(100_000)}")

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  test "create/3 creates SKILL.md and .musician.yaml in the skills directory" do
    assert {:ok, path} = Creator.create(@tmp_dir, "my-skill", "Do something useful when asked.")
    assert File.exists?(Path.join(path, "SKILL.md"))
    assert File.exists?(Path.join(path, ".musician.yaml"))
  end

  test "create/3 SKILL.md contains the skill name" do
    {:ok, path} = Creator.create(@tmp_dir, "my-skill", "Do something.")
    content = File.read!(Path.join(path, "SKILL.md"))
    assert String.contains?(content, "my-skill")
  end

  test "create/3 .musician.yaml sets status to draft" do
    {:ok, path} = Creator.create(@tmp_dir, "draft-skill", "A draft.")
    content = File.read!(Path.join(path, ".musician.yaml"))
    assert String.contains?(content, "draft")
  end
end
