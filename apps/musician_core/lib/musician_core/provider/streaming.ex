defmodule MusicianCore.Provider.Streaming do
  @moduledoc """
  Server-Sent Events (SSE) parser for streaming LLM responses.
  Parses the `data: {...}` lines from a streaming HTTP response.
  """

  @doc """
  Parses a raw SSE chunk string into a list of decoded maps.
  Filters out `[DONE]` sentinels and non-data lines.
  """
  @spec parse_chunk(String.t()) :: list(map())
  def parse_chunk(chunk) when is_binary(chunk) do
    chunk
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "data: "))
    |> Enum.map(&String.replace_prefix(&1, "data: ", ""))
    |> Enum.reject(&(&1 == "[DONE]"))
    |> Enum.flat_map(fn json_str ->
      case Jason.decode(json_str) do
        {:ok, decoded} -> [decoded]
        _ -> []
      end
    end)
  end

  @doc """
  Extracts the delta content from a streaming chunk map.
  Returns the content string or nil.
  """
  @spec extract_delta(map()) :: String.t() | nil
  def extract_delta(chunk) when is_map(chunk) do
    get_in(chunk, ["choices", Access.at(0), "delta", "content"])
  end

  @doc """
  Returns true if this chunk signals the end of the stream.
  """
  @spec done?(map()) :: boolean()
  def done?(chunk) when is_map(chunk) do
    get_in(chunk, ["choices", Access.at(0), "finish_reason"]) != nil
  end
end
