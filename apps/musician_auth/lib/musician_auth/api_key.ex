defmodule MusicianAuth.ApiKey do
  @moduledoc """
  Resolves API keys for providers.

  Supports two formats:
  - "env:VAR_NAME"  → reads from System.get_env("VAR_NAME")
  - any other string → used as the literal key value
  """

  @doc """
  Resolves an API key value from a config entry.

  ## Examples

      iex> System.put_env("MY_KEY", "sk-abc")
      iex> MusicianAuth.ApiKey.resolve("env:MY_KEY")
      {:ok, "sk-abc"}

      iex> MusicianAuth.ApiKey.resolve("sk-direct-value")
      {:ok, "sk-direct-value"}

      iex> MusicianAuth.ApiKey.resolve("env:UNSET_VAR_XYZ")
      {:error, :missing}
  """
  @spec resolve(String.t() | nil) :: {:ok, String.t()} | {:error, :missing}
  def resolve(nil), do: {:error, :missing}

  def resolve("env:" <> var_name) do
    case System.get_env(var_name) do
      nil -> {:error, :missing}
      "" -> {:error, :missing}
      key -> {:ok, key}
    end
  end

  def resolve(key) when is_binary(key) and byte_size(key) > 0 do
    {:ok, key}
  end

  def resolve(_), do: {:error, :missing}
end
