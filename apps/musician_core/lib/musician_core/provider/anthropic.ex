defmodule MusicianCore.Provider.Anthropic do
  @moduledoc """
  Anthropic Messages API provider. Used when `native: true` is set in provider config.
  Translates between OpenAI message format and Anthropic Messages API format.
  """

  @behaviour MusicianCore.Provider.Behaviour

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{Request, Response, SSEParser}

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
  @spec stream(ProviderConfig.t(), Request.t()) :: {:ok, Enumerable.t()} | {:error, term()}
  def stream(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/messages"
    headers = build_headers(config)
    body = translate_request(request) |> Map.put("stream", true)

    parent = self()
    ref = make_ref()

    Task.start(fn ->
      case Req.post(url,
             json: body,
             headers: headers,
             into: fn {:data, chunk}, {req, resp} ->
               send(parent, {ref, {:data, chunk}})
               {:cont, {req, resp}}
             end,
             receive_timeout: 30_000
           ) do
        {:ok, _resp} -> send(parent, {ref, :done})
        {:error, reason} -> send(parent, {ref, {:error, reason}})
      end
    end)

    stream =
      Stream.resource(
        fn -> ref end,
        fn ref ->
          receive do
            {^ref, {:data, chunk}} ->
              chunks =
                SSEParser.parse_chunk(chunk)
                |> Enum.map(&translate_sse_event/1)
                |> Enum.reject(&is_nil/1)

              {chunks, ref}

            {^ref, {:error, reason}} ->
              throw({:stream_error, reason})

            {^ref, :done} ->
              {:halt, ref}
          after
            30_000 -> {:halt, ref}
          end
        end,
        fn _ref -> :ok end
      )

    {:ok, stream}
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

  @doc """
  Translates an Anthropic Messages API response body to a MusicianCore.Response.
  """
  @spec translate_response(map()) :: Response.t()
  def translate_response(body) when is_map(body) do
    content =
      body
      |> Map.get("content", [])
      |> Enum.find_value(nil, fn
        %{"type" => "text", "text" => text} -> text
        _ -> false
      end)

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

  # Translates an Anthropic SSE event map to OpenAI-compatible streaming format
  # so the CLI's get_in(chunk, ["choices", Access.at(0), "delta", "content"])
  # works without changes.
  @spec translate_sse_event(map()) :: map() | nil
  defp translate_sse_event(%{
         "type" => "content_block_delta",
         "index" => index,
         "delta" => %{"type" => "text_delta", "text" => text}
       }) do
    %{"choices" => [%{"index" => index, "delta" => %{"content" => text}}]}
  end

  defp translate_sse_event(%{
         "type" => "message_delta",
         "delta" => %{"stop_reason" => reason}
       }) do
    %{"choices" => [%{"finish_reason" => reason}]}
  end

  defp translate_sse_event(%{"type" => "message_start", "message" => message}) do
    %{"id" => Map.get(message, "id"), "choices" => [%{"index" => 0, "delta" => %{}}]}
  end

  defp translate_sse_event(_), do: nil
end
