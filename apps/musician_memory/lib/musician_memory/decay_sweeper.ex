defmodule MusicianMemory.DecaySweeper do
  @moduledoc """
  Scans memories and removes entries flagged as stale by Decay.stale?/1.

  Each call to run/0 opens the SQLite DB and closes it on exit.
  This means the DB may be closed between sweeps (up to 24h).
  This is acceptable for a background cleanup process: if the sweep
  is delayed or skipped, stale entries will be cleaned up on the next run.
  """

  alias MusicianMemory.Decay
  alias MusicianMemory.Repo

  @doc """
  Scans all memories, deletes those flagged as stale by Decay.stale?/1.
  Returns :ok.
  """
  def run do
    {:ok, db} = Repo.init(Application.fetch_env!(:musician_memory, :db_path))
    on_exit(fn -> Repo.close(db) end)
    sweep_all(db)
  end

  defp sweep_all(db) do
    {:ok, rows} = Repo.all_memories(db)

    stale_ids =
      for %{id: id, updated_at: updated_at} <- rows,
          Decay.stale?(%{updated_at: updated_at}),
          do: id

    if stale_ids != [],
      do: Repo.delete_stale(db, stale_ids)

    :ok
  end
end
