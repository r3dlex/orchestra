defmodule MusicianSession.Search do
  @moduledoc "Search session history by keyword or time range."

  def by_keyword(sessions, keyword) do
    kw = String.downcase(keyword)

    Enum.filter(sessions, fn s ->
      summary = String.downcase(s["prompt_summary"] || "")
      String.contains?(summary, kw)
    end)
  end

  def by_time_range(sessions, start_iso, end_iso) do
    {:ok, start_dt, _} = DateTime.from_iso8601(start_iso)
    {:ok, end_dt, _} = DateTime.from_iso8601(end_iso)

    Enum.filter(sessions, fn s ->
      case DateTime.from_iso8601(s["timestamp"] || "") do
        {:ok, dt, _} ->
          DateTime.compare(dt, start_dt) in [:gt, :eq] and
            DateTime.compare(dt, end_dt) in [:lt, :eq]

        _ ->
          false
      end
    end)
  end
end
