defmodule MusicianCore.Provider.SSEParser do
  @moduledoc "Parse Server-Sent Events chunks into decoded maps."

  def parse_chunk(raw) do
    raw
    |> String.split("\n")
    |> Enum.flat_map(&parse_event/1)
  end

  defp parse_event(event) do
    event
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "data: "))
    |> Enum.flat_map(fn "data: " <> data ->
      case String.trim(data) do
        "[DONE]" ->
          []

        json ->
          case Jason.decode(json) do
            {:ok, decoded} -> [decoded]
            {:error, _} -> []
          end
      end
    end)
  end
end
