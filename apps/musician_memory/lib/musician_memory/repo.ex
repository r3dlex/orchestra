defmodule MusicianMemory.Repo do
  @moduledoc "SQLite + FTS5 storage for memories."

  def init(db_path) do
    {:ok, db} = Exqlite.Sqlite3.open(db_path)
    create_tables(db)
    {:ok, db}
  end

  def close(db), do: Exqlite.Sqlite3.close(db)

  def insert(db, %{type: type, scope: scope, body: body, tags: tags}) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    sql = "INSERT INTO memories (type, scope, body, tags, created_at, updated_at) VALUES (?1, ?2, ?3, ?4, ?5, ?5)"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
    :ok = Exqlite.Sqlite3.bind(stmt, [type, scope, body, tags, now])
    :done = Exqlite.Sqlite3.step(db, stmt)
    :ok = Exqlite.Sqlite3.release(db, stmt)
    {:ok, last_insert_rowid(db)}
  end

  def get(db, id) do
    sql = "SELECT id, type, scope, body, tags, created_at, updated_at FROM memories WHERE id = ?1"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
    :ok = Exqlite.Sqlite3.bind(stmt, [id])
    case Exqlite.Sqlite3.step(db, stmt) do
      {:row, row} ->
        :ok = Exqlite.Sqlite3.release(db, stmt)
        {:ok, row_to_map(row)}
      :done ->
        :ok = Exqlite.Sqlite3.release(db, stmt)
        {:error, :not_found}
    end
  end

  def search(db, query) do
    sql = "SELECT m.id, m.type, m.scope, m.body, m.tags, m.created_at, m.updated_at FROM memories_fts fts JOIN memories m ON fts.rowid = m.id WHERE memories_fts MATCH ?1"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
    :ok = Exqlite.Sqlite3.bind(stmt, [query])
    rows = collect_rows(db, stmt, [])
    :ok = Exqlite.Sqlite3.release(db, stmt)
    {:ok, rows}
  end

  def update(db, id, changes) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    sets = changes |> Map.keys() |> Enum.map_join(", ", fn k -> "#{k} = ?1" end)
    vals = Map.values(changes)
    sql = "UPDATE memories SET #{sets}, updated_at = '#{now}' WHERE id = #{id}"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
    :ok = Exqlite.Sqlite3.bind(stmt, vals)
    :done = Exqlite.Sqlite3.step(db, stmt)
    :ok = Exqlite.Sqlite3.release(db, stmt)
    :ok
  end

  def delete(db, id) do
    sql = "DELETE FROM memories WHERE id = ?1"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, sql)
    :ok = Exqlite.Sqlite3.bind(stmt, [id])
    :done = Exqlite.Sqlite3.step(db, stmt)
    :ok = Exqlite.Sqlite3.release(db, stmt)
    :ok
  end

  defp create_tables(db) do
    Exqlite.Sqlite3.execute(db, """
    CREATE TABLE IF NOT EXISTS memories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      scope TEXT NOT NULL,
      body TEXT NOT NULL,
      tags TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """)
    Exqlite.Sqlite3.execute(db, """
    CREATE VIRTUAL TABLE IF NOT EXISTS memories_fts USING fts5(
      body, tags, content=memories, content_rowid=id
    )
    """)
    Exqlite.Sqlite3.execute(db, """
    CREATE TRIGGER IF NOT EXISTS memories_ai AFTER INSERT ON memories BEGIN
      INSERT INTO memories_fts(rowid, body, tags) VALUES (new.id, new.body, new.tags);
    END
    """)
    :ok
  end

  defp last_insert_rowid(db) do
    {:ok, stmt} = Exqlite.Sqlite3.prepare(db, "SELECT last_insert_rowid()")
    {:row, [id]} = Exqlite.Sqlite3.step(db, stmt)
    :ok = Exqlite.Sqlite3.release(db, stmt)
    id
  end

  defp collect_rows(db, stmt, acc) do
    case Exqlite.Sqlite3.step(db, stmt) do
      {:row, row} -> collect_rows(db, stmt, [row_to_map(row) | acc])
      :done -> Enum.reverse(acc)
    end
  end

  defp row_to_map([id, type, scope, body, tags, created_at, updated_at]) do
    %{"id" => id, "type" => type, "scope" => scope, "body" => body,
      "tags" => tags, "created_at" => created_at, "updated_at" => updated_at}
  end
end
