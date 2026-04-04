defmodule MusicianCore.TokenStore do
  @moduledoc """
  Behaviour wrapper around `MusicianAuth.TokenStore` so it can be mocked in tests.

  Allows injecting `MusicianCore.TokenStoreMock` (or any mock module) in place of
  the real token store without depending on the filesystem.
  """

  @doc "Reads tokens for the given scope (e.g. \"codex\")."
  @callback read(scope :: String.t()) ::
              {:ok, map()} | {:error, :not_found | :parse_error}

  @doc "Writes tokens for the given scope."
  @callback write(scope :: String.t(), tokens :: map()) :: :ok | {:error, term()}

  @behaviour MusicianCore.TokenStore

  @impl true
  defdelegate read(scope), to: MusicianAuth.TokenStore
  @impl true
  defdelegate write(scope, tokens), to: MusicianAuth.TokenStore
end
