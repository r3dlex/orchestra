defmodule MusicianCore.Provider.OpenAICompat do
  @moduledoc """
  OpenAI-compatible provider. Works with MiniMax, Codex, Gemini (OpenAI-compat endpoint),
  Ollama, OpenRouter, or any custom /chat/completions endpoint.
  """

  @behaviour MusicianCore.Provider.Behaviour

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{Request, Response}

  @impl true
  def name, do: "openai_compat"

  @impl true
  def complete(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/chat/completions"
    headers = build_headers(config)
    body = Request.to_map(%{request | stream: false})

    case Req.post(url, json: body, headers: headers) do
      {:ok, %{status: 200, body: resp_body}} ->
        {:ok, Response.from_openai(resp_body)}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 429, headers: resp_headers}} ->
        {:error, {:rate_limited, retry_after(resp_headers)}}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, {:api_error, status, resp_body}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end

  @impl true
  def stream(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/chat/completions"
    headers = build_headers(config)
    body = Request.to_map(%{request | stream: true})

    # Return a stream of parsed SSE chunk maps
    stream =
      Stream.resource(
        fn -> start_stream(url, headers, body) end,
        &next_chunk/1,
        &cleanup_stream/1
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

  # --- Private ---

  defp build_headers(%ProviderConfig{api_key_env: nil}), do: []

  defp build_headers(%ProviderConfig{api_key_env: env_var}) do
    key = System.get_env(env_var) || ""
    [{"authorization", "Bearer #{key}"}]
  end

  defp retry_after(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, value} -> String.to_integer(value)
      nil -> 60
    end
  end

  # Stream resource callbacks — minimal implementation for now
  defp start_stream(url, headers, body), do: {url, headers, body, []}
  defp next_chunk({_url, _headers, _body, []}), do: {:halt, nil}
  defp cleanup_stream(_), do: :ok
end
