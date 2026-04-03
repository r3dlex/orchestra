defmodule MusicianSkills.Improver do
  @moduledoc "Self-improvement loop for skills."

  alias MusicianSkills.Sidecar

  def improve(skill_path, note) do
    sidecar_path = Path.join(skill_path, ".musician.yaml")

    case Sidecar.read(sidecar_path) do
      {:ok, data} ->
        count = (data["improved_count"] || 0) + 1

        updated =
          Map.merge(data, %{
            "improved_count" => count,
            "last_improved" => DateTime.utc_now() |> DateTime.to_iso8601()
          })

        improvements = data["improvements"] || []
        updated = Map.put(updated, "improvements", improvements ++ [%{"note" => note}])
        Sidecar.write(sidecar_path, updated)
        {:ok, count}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
