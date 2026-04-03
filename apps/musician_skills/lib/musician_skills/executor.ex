defmodule MusicianSkills.Executor do
  @moduledoc "Execute a skill in a given context."

  def execute(skill, context) when is_map(skill) and is_map(context) do
    {:ok, %{skill: skill.name, body: skill.body, context: context}}
  end
end
