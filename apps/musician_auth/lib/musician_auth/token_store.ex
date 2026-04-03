defmodule MusicianAuth.TokenStore do
  @moduledoc """
  Reads and writes token files to ~/.musician/auth/.
  Token files are YAML format.
  """

  @auth_dir "~/.musician/auth"

  @doc """
  Reads a token file by name (without extension).
  Returns {:ok, map()} or {:error, :not_found | :parse_error}.

  ## Examples

      MusicianAuth.TokenStore.read("codex")
      # => {:ok, %{"auth_mode" => "device", "tokens" => %{...}}}
  """
  @spec read(String.t()) :: {:ok, map()} | {:error, :not_found | :parse_error}
  def read(name) do
    path = token_path(name)

    case File.read(path) do
      {:ok, content} ->
        case YamlElixir.read_from_string(content) do
          {:ok, parsed} when is_map(parsed) -> {:ok, parsed}
          _ -> {:error, :parse_error}
        end

      {:error, _} ->
        {:error, :not_found}
    end
  end

  @doc """
  Writes a token map to ~/.musician/auth/<name>.yaml.
  Creates the directory if it doesn't exist.
  Returns :ok or {:error, reason}.
  """
  @spec write(String.t(), map()) :: :ok | {:error, term()}
  def write(name, tokens) when is_map(tokens) do
    dir = Path.expand(@auth_dir)
    path = token_path(name)

    with :ok <- File.mkdir_p(dir),
         yaml <- map_to_yaml(tokens),
         :ok <- File.write(path, yaml) do
      :ok
    end
  end

  @doc "Returns the full path for a token file."
  @spec token_path(String.t()) :: String.t()
  def token_path(name) do
    Path.join([Path.expand(@auth_dir), "#{name}.yaml"])
  end

  # Minimal YAML serializer — for simple flat/nested maps with string values
  defp map_to_yaml(map, indent \\ 0) do
    prefix = String.duplicate("  ", indent)

    Enum.map_join(map, "\n", fn {key, value} ->
      cond do
        is_map(value) ->
          "#{prefix}#{key}:\n#{map_to_yaml(value, indent + 1)}"

        is_binary(value) or is_integer(value) or is_float(value) ->
          "#{prefix}#{key}: #{value}"

        is_nil(value) ->
          "#{prefix}#{key}: null"

        true ->
          "#{prefix}#{key}: #{inspect(value)}"
      end
    end)
  end
end
