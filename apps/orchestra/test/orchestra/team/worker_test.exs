defmodule Orchestra.Team.WorkerTest do
  use ExUnit.Case, async: true
  alias Orchestra.Team.Worker

  test "spawn/4 returns {:ok, worker_map} with required fields" do
    assert {:ok, worker} = Worker.spawn("worker-1", {:musician, "minimax"}, "do task", "/tmp/wt")
    assert worker.id == "worker-1"
    assert worker.backend == {:musician, "minimax"}
    assert worker.status == :running
  end

  test "worker_map has pane field" do
    {:ok, worker} = Worker.spawn("w2", {:claude, nil}, "task", "/tmp")
    assert Map.has_key?(worker, :pane)
  end
end
