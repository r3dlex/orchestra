defmodule MusicianTools.FileRead do
  @moduledoc "Tool: read a file from the filesystem."

  def name, do: "file_read"
  def description, do: "Read the contents of a file at the given path."

  def schema do
    %{
      path: %{type: :string, description: "Absolute or relative path to the file", required: true}
    }
  end

  def execute(%{path: path}) do
    case File.read(path) do
      {:ok, _} = ok -> ok
      {:error, :enoent} -> {:error, :not_found}
      {:error, _} = err -> err
    end
  end
end
