defmodule MusicianCore.Provider.OpenAICompat do
  @moduledoc """
  OpenAI-compatible provider. Works with MiniMax, Codex, Gemini (OpenAI-compat endpoint),
  Ollama, OpenRouter, or any custom /chat/completions endpoint.
  """

  @behaviour MusicianCore.Provider.Behaviour

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{Request, Response, SSEParser}
  alias MusicianAuth.ApiKey

  # Swap MusicianCore.HTTPMock for MusicianCore.HTTP in tests via Application.put_env
  # Swap MusicianCore.TokenStoreMock for MusicianCore.TokenStore in tests via Application.put_env
  defp http, do: Application.get_env(:musician_core, :http_client, MusicianCore.HTTP)
  defp token_store, do: Application.get_env(:musician_core, :token_store, MusicianCore.TokenStore)

  @impl true
  def name, do: "openai_compat"

  @impl true
  def complete(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/chat/completions"
    headers = build_headers(config)
    body = Request.to_map(%{request | stream: false})

    case http().post(url, body, headers) do
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
  @spec stream(ProviderConfig.t(), Request.t()) :: {:ok, Enumerable.t()} | {:error, term()}
  def stream(%ProviderConfig{} = config, %Request{} = request) do
    url = "#{config.api_base}/chat/completions"
    headers = build_headers(config)
    body = Request.to_map(%{request | stream: true})

    parent = self()
    ref = make_ref()

    Task.start(fn ->
      http().post_streaming(
        url,
        body,
        headers,
        fn {:data, chunk}, {req, resp} ->
          send(parent, {ref, {:data, chunk}})
          {:cont, {req, resp}}
        end,
        30_000
      )

      send(parent, {ref, :done})
    end)

    stream =
      Stream.resource(
        fn -> ref end,
        fn ref ->
          receive do
            {^ref, {:data, chunk}} ->
              {SSEParser.parse_chunk(chunk), ref}

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

    case http().get(url, headers) do
      {:ok, %{status: 200, body: %{"data" => models}}} -> {:ok, models}
      {:ok, %{status: status, body: body}} -> {:error, {:api_error, status, body}}
      {:error, reason} -> {:error, {:network, reason}}
    end
  end

  @impl true
  def supports_tools?, do: true

  # Handle device auth (Codex tokens from TokenStore)
  defp build_headers(%ProviderConfig{auth_method: :device}) do
    case token_store().read("codex") do
      {:ok, tokens} when is_map(tokens) ->
        case tokens["access_token"] do
          token when is_binary(token) and byte_size(token) > 0 ->
            [{"authorization", "Bearer #{token}"}]

          _ ->
            []
        end

      {:error, _} ->
        []
    end
  end

  # No API key configured (e.g. Ollama local)
  defp build_headers(%ProviderConfig{api_key_env: nil}), do: []

  # Standard API key auth via env:var or literal key
  defp build_headers(%ProviderConfig{api_key_env: api_key_env}) do
    case ApiKey.resolve(api_key_env) do
      {:ok, key} -> [{"authorization", "Bearer #{key}"}]
      {:error, :missing} -> [{"authorization", "Bearer unauthorized"}]
    end
  end

  defp retry_after(headers) do
    case List.keyfind(headers, "retry-after", 0) do
      {_, value} -> String.to_integer(value)
      nil -> 60
    end
  end
end
