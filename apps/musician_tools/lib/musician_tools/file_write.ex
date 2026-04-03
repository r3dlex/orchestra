defmodule MusicianTools.FileWrite do
  @moduledoc "Tool: write content to a file."

  def name, do: "file_write"
  def description, do: "Write content to a file at the given path, creating it if needed."

  def schema do
    %{
      path: %{type: :string, description: "Path to write the file", required: true},
      content: %{type: :string, description: "Content to write", required: true}
    }
  end

  def execute(%{path: path, content: content}) do
    case File.write(path, content) do
      :ok -> {:ok, path}
      {:error, reason} -> {:error, reason}
    end
  end
end
