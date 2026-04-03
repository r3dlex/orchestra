defmodule Orchestra.Team.StateTest do
  use ExUnit.Case, async: true
  alias Orchestra.Team.State

  @tmp_path System.tmp_dir!() |> Path.join("orchestra_state_test_#{:rand.uniform(100_000)}.json")

  setup do
    on_exit(fn -> File.rm(@tmp_path) end)
    :ok
  end

  test "save/2 and load/1 round-trip state" do
    state = %{phase: "executing", workers: [], task: "test task"}
    :ok = State.save(@tmp_path, state)
    assert {:ok, loaded} = State.load(@tmp_path)
    assert loaded["phase"] == "executing"
    assert loaded["task"] == "test task"
  end

  test "load/1 returns {:error, :not_found} when file does not exist" do
    assert {:error, :not_found} = State.load("/nonexistent/state.json")
  end
end
