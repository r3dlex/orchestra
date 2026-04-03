defmodule MusicianSkills.Sidecar do
  @moduledoc "Read/write .musician.yaml sidecar files."

  def read(path) do
    case File.read(path) do
      {:ok, content} ->
        case YamlElixir.read_from_string(content) do
          {:ok, data} -> {:ok, data}
          {:error, reason} -> {:error, {:parse_error, reason}}
        end
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def write(path, data) do
    yaml = to_yaml(data)
    File.write(path, yaml)
  end

  defp to_yaml(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> "#{k}: #{inspect_value(v)}" end)
    |> Enum.join("\n")
    |> Kernel.<>("\n")
  end

  defp inspect_value(v) when is_binary(v), do: v
  defp inspect_value(v) when is_integer(v), do: Integer.to_string(v)
  defp inspect_value(v) when is_float(v), do: Float.to_string(v)
  defp inspect_value(v) when is_boolean(v), do: Atom.to_string(v)
  defp inspect_value(v), do: inspect(v)
end
