defmodule MusicianMemory.DecaySweeperTest do
  use ExUnit.Case, async: false

  alias MusicianMemory.DecaySweeper
  alias MusicianMemory.Repo

  setup do
    db_path = System.tmp_dir!() |> Path.join("musician_memory_sweeper_test_#{:rand.uniform(100_000)}.db")
    {:ok, db} = Repo.init(db_path)

    on_exit(fn ->
      Repo.close(db)
      File.rm(db_path)
    end)

    {:ok, db: db}
  end

  test "run/0 deletes stale memories and keeps fresh ones", %{db: db} do
    old_date =
      DateTime.utc_now() |> DateTime.add(-95 * 24 * 3600, :second) |> DateTime.to_iso8601()

    fresh_date = DateTime.utc_now() |> DateTime.to_iso8601()

    {:ok, stale_id} =
      Repo.insert(db, %{type: "project", scope: "private", body: "stale body", tags: ""})

    {:ok, _} =
      Repo.insert(db, %{type: "project", scope: "private", body: "fresh body", tags: ""})

    Repo.update(db, stale_id, %{"updated_at" => old_date})

    assert :ok = DecaySweeper.run()

    {:ok, rows} = Repo.all_memories(db)
    assert length(rows) == 1
    assert hd(rows)["body"] == "fresh body"
  end

  test "run/0 keeps reference type memories even if old", %{db: db} do
    old_date =
      DateTime.utc_now() |> DateTime.add(-365 * 24 * 3600, :second) |> DateTime.to_iso8601()

    {:ok, id} =
      Repo.insert(db, %{
        type: "reference",
        scope: "private",
        body: "important reference",
        tags: ""
      })

    Repo.update(db, id, %{"updated_at" => old_date})

    assert :ok = DecaySweeper.run()

    {:ok, rows} = Repo.all_memories(db)
    assert length(rows) == 1
    assert hd(rows)["body"] == "important reference"
  end

  test "run/0 handles empty database gracefully", %{db: db} do
    assert :ok = DecaySweeper.run()
  end
end
