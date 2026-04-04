defmodule MusicianMemory.RepoTest do
  use ExUnit.Case, async: false

  alias MusicianMemory.Repo

  setup do
    db_path = System.tmp_dir!() |> Path.join("musician_memory_test_#{:rand.uniform(100_000)}.db")
    {:ok, db} = Repo.init(db_path)

    on_exit(fn ->
      Repo.close(db)
      File.rm(db_path)
    end)

    {:ok, db: db}
  end

  test "insert/2 and get/2 round-trip a memory record", %{db: db} do
    {:ok, id} =
      Repo.insert(db, %{
        type: "feedback",
        scope: "private",
        body: "Always use parallel tool calls",
        tags: "tools,parallel"
      })

    assert is_integer(id)
    {:ok, record} = Repo.get(db, id)
    assert record["body"] == "Always use parallel tool calls"
    assert record["type"] == "feedback"
  end

  test "search/2 returns matching memories by FTS", %{db: db} do
    Repo.insert(db, %{
      type: "user",
      scope: "private",
      body: "Andre is an Elixir developer",
      tags: "elixir"
    })

    Repo.insert(db, %{
      type: "project",
      scope: "team",
      body: "Project uses PostgreSQL",
      tags: "database"
    })

    {:ok, results} = Repo.search(db, "Elixir")
    assert results != []
    assert Enum.any?(results, &String.contains?(&1["body"], "Elixir"))
  end

  test "delete/2 removes a memory record", %{db: db} do
    {:ok, id} = Repo.insert(db, %{type: "user", scope: "private", body: "temp", tags: ""})
    :ok = Repo.delete(db, id)
    assert {:error, :not_found} = Repo.get(db, id)
  end

  test "update/3 updates a memory record", %{db: db} do
    {:ok, id} = Repo.insert(db, %{type: "feedback", scope: "private", body: "old body", tags: ""})
    :ok = Repo.update(db, id, %{body: "new body"})
    {:ok, record} = Repo.get(db, id)
    assert record["body"] == "new body"
  end

  test "all_memories/1 returns all records", %{db: db} do
    {:ok, id1} = Repo.insert(db, %{type: "user", scope: "private", body: "body1", tags: ""})
    {:ok, id2} = Repo.insert(db, %{type: "project", scope: "team", body: "body2", tags: ""})

    {:ok, rows} = Repo.all_memories(db)
    assert length(rows) == 2
    ids = Enum.map(rows, & &1["id"])
    assert id1 in ids
    assert id2 in ids
  end

  test "delete_stale/2 deletes multiple records by id list", %{db: db} do
    {:ok, id1} = Repo.insert(db, %{type: "user", scope: "private", body: "body1", tags: ""})
    {:ok, id2} = Repo.insert(db, %{type: "project", scope: "private", body: "body2", tags: ""})
    {:ok, id3} = Repo.insert(db, %{type: "feedback", scope: "private", body: "body3", tags: ""})

    :ok = Repo.delete_stale(db, [id1, id3])

    {:ok, rows} = Repo.all_memories(db)
    assert length(rows) == 1
    assert hd(rows)["id"] == id2
  end

  test "delete_stale/2 handles empty list gracefully", %{db: db} do
    :ok = Repo.delete_stale(db, [])
    {:ok, rows} = Repo.all_memories(db)
    assert rows == []
  end
end
