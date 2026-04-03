defmodule MusicianSession.Resume do
  @moduledoc "Resume a previous session by ID."

  def find_by_id(sessions, session_id) do
    case Enum.find(sessions, &(&1["session_id"] == session_id)) do
      nil -> {:error, :not_found}
      session -> {:ok, session}
    end
  end
end
