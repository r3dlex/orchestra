defmodule MusicianAuth.Pkce do
  @moduledoc """
  PKCE (Proof Key for Code Exchange) utilities for OAuth 2.0 flows.
  Used by Codex Device Code flow and future Gemini OAuth (v1.1).

  Implements S256 challenge method as per RFC 7636.
  """

  @verifier_length 64

  @doc """
  Generates a cryptographically random code verifier.
  Returns a base64url-encoded string of #{@verifier_length} random bytes.
  """
  @spec generate_verifier() :: String.t()
  def generate_verifier do
    @verifier_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Generates the S256 code challenge from a code verifier.
  challenge = BASE64URL(SHA256(verifier))

  ## Examples

      iex> verifier = MusicianAuth.Pkce.generate_verifier()
      iex> challenge = MusicianAuth.Pkce.generate_challenge(verifier)
      iex> byte_size(challenge) > 0
      true
  """
  @spec generate_challenge(String.t()) :: String.t()
  def generate_challenge(verifier) when is_binary(verifier) do
    :crypto.hash(:sha256, verifier)
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Verifies that a challenge was derived from the given verifier.
  """
  @spec valid_challenge?(String.t(), String.t()) :: boolean()
  def valid_challenge?(verifier, challenge) do
    generate_challenge(verifier) == challenge
  end
end
