defmodule MusicianPlugins.Registry do
  @moduledoc "Plugin registry — register, lookup, and list plugins."

  def new, do: %{}

  def register(registry, name, plugin_info) do
    Map.put(registry, name, plugin_info)
  end

  def lookup(registry, name) do
    case Map.fetch(registry, name) do
      {:ok, plugin} -> {:ok, plugin}
      :error -> {:error, :not_found}
    end
  end

  def list(registry), do: Map.to_list(registry)
end
