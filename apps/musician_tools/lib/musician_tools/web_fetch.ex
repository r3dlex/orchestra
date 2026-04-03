defmodule MusicianTools.WebFetch do
  @moduledoc "Tool: fetch a URL and return the response body."

  def name, do: "web_fetch"
  def description, do: "Fetch a URL via HTTP GET and return the response body as a string."

  def schema do
    %{
      url: %{type: :string, description: "The URL to fetch", required: true}
    }
  end

  def execute(%{url: url}) do
    try do
      case Req.get(url) do
        {:ok, %{status: status, body: body}} when status in 200..299 ->
          {:ok, if(is_binary(body), do: body, else: inspect(body))}

        {:ok, %{status: status}} ->
          {:error, {:http_error, status}}

        {:error, %{reason: reason}} ->
          {:error, {:network, reason}}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e in ArgumentError -> {:error, {:invalid_request, e.message}}
    end
  end
end
