defmodule MusicianSkills.Loader do
  @moduledoc "Loads and parses SKILL.md files."

  def load(skill_path) do
    skill_md = Path.join(skill_path, "SKILL.md")

    case File.read(skill_md) do
      {:ok, content} -> parse(content)
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse(content) do
    case String.split(content, ~r/^---\s*$/m, parts: 3) do
      [_, frontmatter, body] ->
        case YamlElixir.read_from_string(frontmatter) do
          {:ok, meta} ->
            {:ok,
             %{
               name: meta["name"],
               description: meta["description"],
               version: meta["version"] || "1.0",
               triggers: meta["triggers"] || [],
               body: String.trim(body)
             }}

          {:error, reason} ->
            {:error, {:parse_error, reason}}
        end

      _ ->
        {:ok,
         %{name: nil, description: nil, version: "1.0", triggers: [], body: String.trim(content)}}
    end
  end
end
