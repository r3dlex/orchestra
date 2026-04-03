defmodule MusicianCore.Provider.Behaviour do
  @moduledoc """
  Behaviour that all Musician provider modules must implement.
  """

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{Request, Response}

  @doc "Returns the provider's canonical name (e.g. \"minimax\", \"claude\")."
  @callback name() :: String.t()

  @doc "Sends a blocking completion request. Returns {:ok, Response.t()} or {:error, term()}."
  @callback complete(config :: ProviderConfig.t(), request :: Request.t()) ::
              {:ok, Response.t()} | {:error, term()}

  @doc "Starts a streaming completion. Returns {:ok, Enumerable.t()} or {:error, term()}."
  @callback stream(config :: ProviderConfig.t(), request :: Request.t()) ::
              {:ok, Enumerable.t()} | {:error, term()}

  @doc "Lists available models for this provider."
  @callback list_models(config :: ProviderConfig.t()) ::
              {:ok, list(map())} | {:error, term()}

  @doc "Returns true if this provider supports tool/function calling."
  @callback supports_tools?() :: boolean()
end
