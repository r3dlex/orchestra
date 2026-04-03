defmodule MusicianSkills.QualityGateTest do
  use ExUnit.Case, async: true

  alias MusicianSkills.QualityGate

  @tmp_dir System.tmp_dir!() |> Path.join("musician_qg_test_#{:rand.uniform(100_000)}")

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  test "validate/1 returns {:ok, :passed} for skill with no tests directory" do
    skill_path = Path.join(@tmp_dir, "no-tests-skill")
    File.mkdir_p!(skill_path)
    File.write!(Path.join(skill_path, "SKILL.md"), "---\nname: no-tests-skill\n---\nBody.")
    assert {:ok, :passed} = QualityGate.validate(skill_path)
  end

  test "validate/1 returns {:error, :not_found} for missing skill path" do
    assert {:error, :not_found} = QualityGate.validate("/nonexistent/skill")
  end
end
