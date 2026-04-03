defmodule MusicianMemory.Nudge do
  def should_nudge?(%{last_nudge_at: nil}), do: true

  def should_nudge?(%{last_nudge_at: last_nudge_at, interval_minutes: interval_minutes}) do
    case DateTime.from_iso8601(last_nudge_at) do
      {:ok, dt, _} ->
        elapsed = DateTime.diff(DateTime.utc_now(), dt, :second) / 60
        elapsed >= interval_minutes
      _ -> true
    end
  end

  def nudge_message do
    "Would you like to save anything from this session to memory? (user context, decisions, references)"
  end
end
