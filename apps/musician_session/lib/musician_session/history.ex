defmodule MusicianSession.History do
  @moduledoc "JSONL session history — append, read, prune."

  @max_entries Application.get_env(:musician_session, :max_entries, 500)

  def append(path, entry) do
    line = Jason.encode!(entry) <> "\n"
    File.write(path, line, [:append])
    maybe_prune(path)
  end

  def read_all(path) do
    case File.read(path) do
      {:ok, content} ->
        entries =
          content
          |> String.split("\n", trim: true)
          |> Enum.map(&Jason.decode!/1)

        {:ok, entries}

      {:error, :enoent} ->
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def prune(path, keep_count) do
    case read_all(path) do
      {:ok, entries} ->
        kept = Enum.take(entries, -keep_count)
        lines = Enum.map_join(kept, "\n", &Jason.encode!/1) <> "\n"
        File.write(path, lines)

      {:error, :not_found} ->
        :ok

      error ->
        error
    end
  end

  defp maybe_prune(path) do
    case count_lines(path) do
      n when n > @max_entries -> prune(path, @max_entries)
      _ -> :ok
    end
  end

  defp count_lines(path) do
    path |> File.stream!() |> Enum.count()
  end
end
