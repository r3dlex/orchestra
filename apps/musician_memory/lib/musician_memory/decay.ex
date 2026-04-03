defmodule MusicianMemory.Decay do
  @decay_days 90
  @no_decay_types ["reference"]

  def stale?(record) do
    if record["type"] in @no_decay_types do
      false
    else
      case DateTime.from_iso8601(record["updated_at"]) do
        {:ok, dt, _} ->
          age_days = DateTime.diff(DateTime.utc_now(), dt, :second) / 86_400
          age_days > @decay_days
        _ -> false
      end
    end
  end

  def flag_stale(db, id) do
    MusicianMemory.Repo.update(db, id, %{tags: "stale"})
  end
end
