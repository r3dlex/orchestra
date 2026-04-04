defmodule MusicianCore.Config.Loader.Behaviour do
  @moduledoc """
  Behaviour for config loaders. Allows swapping the implementation for testing.
  """

  alias MusicianCore.Config.Schema

  @doc "Load configuration. Returns {:ok, schema} or {:error, reason}."
  @callback load() :: {:ok, Schema.t()} | {:error, term()}

  @doc "Load configuration from explicit paths."
  @callback load(keyword()) :: {:ok, Schema.t()} | {:error, term()}
end
