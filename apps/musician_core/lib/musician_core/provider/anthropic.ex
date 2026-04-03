defmodule MusicianCore.Provider.Anthropic do
  @moduledoc """
  Anthropic Messages API provider. Used when `native: true` is set in provider config.
  Translates between OpenAI message format and Anthropic Messages API format.
  """

  @behaviour MusicianCore.Provider.Behaviour

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{Request, Response}

  @anthropic_version "2023-06-01"

  @impl true
  def name, do: "anthropic"

  @impl true
  def complete(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/messages"
    headers = build_headers(config)
    body = translate_request(request)

    case Req.post(url, json: body, headers: headers) do
      {:ok, %{status: 200, body: resp_body}} ->
        {:ok, translate_response(resp_body)}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, {:api_error, status, resp_body}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end

  @impl true
  def stream(%ProviderConfig{} = _config, %Request{} = _request) do
    # Streaming implementation deferred — returns empty stream for now
    {:ok, Stream.resource(fn -> nil end, fn _ -> {:halt, nil} end, fn _ -> :ok end)}
  end

  @impl true
  def list_models(%ProviderConfig{} = config) do
    url = "#{config.api_base}/models"
    headers = build_headers(config)

    case Req.get(url, headers: headers) do
      {:ok, %{status: 200, body: %{"data" => models}}} -> {:ok, models}
      {:ok, %{status: status, body: body}} -> {:error, {:api_error, status, body}}
      {:error, reason} -> {:error, {:network, reason}}
    end
  end

  @impl true
  def supports_tools?, do: true

  @doc """
  Translates an OpenAI-format request map to Anthropic Messages API format.
  """
  @spec translate_request(Request.t()) :: map()
  def translate_request(%Request{} = req) do
    {system, messages} = extract_system(req.messages)

    base = %{
      "model" => req.model,
      "messages" => messages,
      "max_tokens" => req.max_tokens || 4096
    }

    base
    |> maybe_put_system(system)
    |> maybe_put_tools(req.tools)
  end

  # --- Private ---

  defp build_headers(%ProviderConfig{api_key_env: nil}) do
    [{"anthropic-version", @anthropic_version}]
  end

  defp build_headers(%ProviderConfig{api_key_env: env_var}) do
    key = System.get_env(env_var) || ""
    [{"x-api-key", key}, {"anthropic-version", @anthropic_version}]
  end

  defp extract_system(messages) do
    case messages do
      [%{"role" => "system", "content" => content} | rest] -> {content, rest}
      _ -> {nil, messages}
    end
  end

  defp maybe_put_system(map, nil), do: map
  defp maybe_put_system(map, system), do: Map.put(map, "system", system)

  defp maybe_put_tools(map, []), do: map

  defp maybe_put_tools(map, tools) do
    anthropic_tools =
      Enum.map(tools, fn tool ->
        func = tool["function"] || %{}

        %{
          "name" => func["name"],
          "description" => func["description"],
          "input_schema" => func["parameters"] || %{}
        }
      end)

    Map.put(map, "tools", anthropic_tools)
  end

  defp translate_response(body) when is_map(body) do
    content =
      case Map.get(body, "content", []) do
        [%{"type" => "text", "text" => text} | _] -> text
        _ -> nil
      end

    %Response{
      id: Map.get(body, "id"),
      content: content,
      finish_reason: Map.get(body, "stop_reason"),
      usage: parse_usage(Map.get(body, "usage"))
    }
  end

  defp parse_usage(nil), do: nil

  defp parse_usage(usage) do
    %{
      prompt_tokens: Map.get(usage, "input_tokens", 0),
      completion_tokens: Map.get(usage, "output_tokens", 0),
      total_tokens: Map.get(usage, "input_tokens", 0) + Map.get(usage, "output_tokens", 0)
    }
  end
end
