# Musician — Provider System

## Supported Providers

| Provider | Auth | Module | API Style |
|----------|------|--------|-----------|
| MiniMax | `MINIMAX_API_KEY` env | `OpenAICompat` | OpenAI-compat |
| Claude | `ANTHROPIC_API_KEY` env | `Anthropic` | Anthropic Messages API |
| Codex | Device Code flow | `OpenAICompat` | OpenAI-compat |
| Gemini | `GEMINI_API_KEY` env | `OpenAICompat` | OpenAI-compat |
| Ollama | None | `OpenAICompat` | OpenAI-compat |

## ProviderConfig Schema

```elixir
%MusicianCore.Config.Schema.ProviderConfig{
  api_base: "https://api.minimaxi.chat/v1",
  model: "MiniMax-Text-01",
  api_key_env: "MINIMAX_API_KEY"   # env var name, not the key itself
}
```

## Request / Response

```elixir
%MusicianCore.Provider.Request{
  model: "MiniMax-Text-01",
  messages: [%{"role" => "user", "content" => "Hello"}],
  stream: false,
  temperature: 0.7
}

%MusicianCore.Provider.Response{
  content: "Hello!",
  model: "MiniMax-Text-01",
  usage: %{prompt_tokens: 10, completion_tokens: 5}
}
```

## OpenAICompat

Handles any `/chat/completions` endpoint. Key functions:

- `complete/2` — synchronous POST, returns `{:ok, Response.t()}`
- `stream/2` — SSE streaming via `Req into:` callback, returns `{:ok, Stream.t()}`
- `list_models/1` — GET `/models`, returns `{:ok, [String.t()]}`

Error shape: `{:error, {:api_error, status_code, body_map}}`

## SSE Streaming Implementation

```elixir
# openai_compat.ex
Task.start(fn ->
  Req.post(url, json: body, headers: headers,
    into: fn {:data, chunk}, {req, resp} ->
      send(parent, {ref, {:data, chunk}})
      {:cont, {req, resp}}
    end, receive_timeout: 30_000)
  send(parent, {ref, :done})
end)

stream = Stream.resource(
  fn -> ref end,
  fn ref ->
    receive do
      {^ref, {:data, chunk}} -> {SSEParser.parse_chunk(chunk), ref}
      {^ref, :done}          -> {:halt, ref}
    after 30_000              -> {:halt, ref}
    end
  end,
  fn _ref -> :ok end
)
```

`SSEParser.parse_chunk/1` splits on `"\n\n"`, filters `"data: "` prefix lines, skips `"[DONE]"`, JSON-decodes each payload.

## Codex Device Code Flow

Endpoint: `https://auth0.openai.com/oauth/device/code`
Token poll: `https://auth0.openai.com/oauth/token`

Note: `auth0.openai.com` (not `auth.openai.com`). Automated HTTP clients receive 403 from bot-protection — the flow is designed for browser-based user authorization.

Tokens stored at `~/.musician/auth/codex.yaml` via `TokenStore`.

## Adding a New Provider

1. Add a `ProviderConfig` preset in `musician_core/lib/musician_core/config/`
2. If OpenAI-compat: just configure `api_base` and `model` — no new module needed
3. If custom API: implement `MusicianCore.Provider.Behaviour` callbacks
4. Add E2E test in `apps/musician_core/test/musician_core/provider/` tagged `@moduletag :provider_e2e`
