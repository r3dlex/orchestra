defmodule Orchestra.Team.RuntimeTest do
  use ExUnit.Case, async: true
  alias Orchestra.Team.Runtime

  test "transition(:idle, {:start, task}) returns :planning state" do
    assert {:planning, _state} = Runtime.transition({:idle, %{}}, {:start, "do something"})
  end

  test "transition(:planning, :ready) returns :executing state" do
    assert {:executing, _} = Runtime.transition({:planning, %{task: "x"}}, :ready)
  end

  test "transition(:executing, :all_done) returns :verifying state" do
    assert {:verifying, _} = Runtime.transition({:executing, %{workers: []}}, :all_done)
  end

  test "transition(:verifying, :pass) returns :done state" do
    assert {:done, _} = Runtime.transition({:verifying, %{}}, :pass)
  end

  test "transition(:verifying, :fail) returns :fixing state" do
    assert {:fixing, _} = Runtime.transition({:verifying, %{}}, :fail)
  end

  test "transition(:fixing, :ready) returns :executing state" do
    assert {:executing, _} = Runtime.transition({:fixing, %{}}, :ready)
  end
end
