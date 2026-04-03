defmodule Orchestra.Team.State do
  @moduledoc "Persist and load team state as JSON."

  def save(path, state) do
    File.write(path, Jason.encode!(state))
  end

  def load(path) do
    case File.read(path) do
      {:ok, content} -> {:ok, Jason.decode!(content)}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
