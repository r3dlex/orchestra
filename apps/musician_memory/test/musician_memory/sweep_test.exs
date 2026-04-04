defmodule MusicianMemory.SweepTest do
  use ExUnit.Case, async: false

  alias MusicianMemory.Sweep

  setup do
    db_path =
      System.tmp_dir!()
      |> Path.join("musician_memory_sweep_genserver_test_#{:rand.uniform(100_000)}.db")

    Application.put_env(:musician_memory, :db_path, db_path)

    on_exit(fn ->
      File.rm(db_path)
      Application.delete_env(:musician_memory, :db_path)
    end)

    :ok
  end

  test "Sweep GenServer starts and is alive" do
    {:ok, pid} = Sweep.start_link([])
    assert is_pid(pid)
    assert Process.alive?(pid)
    Process.exit(pid, :normal)
  end
end
