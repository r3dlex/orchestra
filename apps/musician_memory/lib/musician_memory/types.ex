defmodule MusicianMemory.Types do
  @types [:user, :feedback, :project, :reference]
  @scopes [:private, :team]

  def types, do: @types
  def scopes, do: @scopes
  def valid_type?(t), do: t in @types
  def valid_scope?(s), do: s in @scopes
end
