defmodule MusicianSession.Resume do
  @moduledoc "Reconstruct a session prompt from history entries."

  alias MusicianSession.History

  def latest do
    path = Application.get_env(:musician_session, :history_path)

    with {:ok, entries} <- History.read_all(path),
         {:ok, last} <- wrap_not_empty(List.last(entries)) do
      {:ok, build_prompt(last)}
    end
  end

  def by_project(project_dir) do
    path = Application.get_env(:musician_session, :history_path)

    with {:ok, entries} <- History.read_all(path) do
      matches =
        entries
        |> Enum.filter(fn e -> e["project_dir"] == project_dir end)
        |> Enum.take(-5)
        |> Enum.map(&build_prompt/1)

      {:ok, matches}
    end
  end

  defp wrap_not_empty(nil), do: {:error, :no_sessions}
  defp wrap_not_empty(entry), do: {:ok, entry}

  defp build_prompt(entry) do
    %{
      project_dir: entry["project_dir"],
      timestamp: entry["timestamp"],
      summary: entry["prompt_summary"],
      token_count: entry["token_count"]
    }
  end
end
