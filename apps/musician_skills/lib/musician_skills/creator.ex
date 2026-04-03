defmodule MusicianSkills.Creator do
  @moduledoc "Create new skills from a name and body description."

  def create(skills_dir, name, body) do
    skill_path = Path.join(skills_dir, name)
    File.mkdir_p!(skill_path)

    skill_md = """
    ---
    name: #{name}
    description: #{body}
    version: "1.0"
    triggers: []
    ---

    #{body}
    """
    File.write!(Path.join(skill_path, "SKILL.md"), skill_md)

    sidecar = """
    created_at: #{DateTime.utc_now() |> DateTime.to_iso8601()}
    improved_count: 0
    status: draft
    total_invocations: 0
    """
    File.write!(Path.join(skill_path, ".musician.yaml"), sidecar)

    {:ok, skill_path}
  end
end
