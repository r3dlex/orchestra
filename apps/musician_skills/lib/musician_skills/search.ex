defmodule MusicianSkills.Search do
  @moduledoc "Find skills by name or trigger pattern."

  def find_by_name(skills, name) do
    Enum.find(skills, fn s -> s.name == name end)
  end

  def find_by_trigger(skills, input) do
    Enum.filter(skills, fn skill ->
      Enum.any?(skill.triggers || [], fn trigger ->
        case Regex.compile(trigger) do
          {:ok, regex} -> Regex.match?(regex, input)
          _ -> String.contains?(input, trigger)
        end
      end)
    end)
  end
end
