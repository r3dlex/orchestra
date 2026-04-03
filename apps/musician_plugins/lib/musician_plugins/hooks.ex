defmodule MusicianPlugins.Hooks do
  @moduledoc "Lifecycle hook dispatch — register and fire event handlers."

  def new, do: %{}

  def register_hook(hooks, event, handler) do
    existing = Map.get(hooks, event, [])
    Map.put(hooks, event, existing ++ [handler])
  end

  def handlers_for(hooks, event), do: Map.get(hooks, event, [])

  def dispatch(hooks, event, context) do
    hooks
    |> handlers_for(event)
    |> Enum.each(fn handler -> handler.(context) end)

    :ok
  end
end
