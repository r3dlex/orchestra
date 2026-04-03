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

## Free-Tier Limitations

**MiniMax free tier**: Non-streaming completions (`stream: false`) return HTTP 500 with body `"token plan not support model"`. The streaming endpoint works on all tiers. E2E tests account for this by matching `{:error, {:api_error, 500, _}}` for non-streaming calls and asserting `true`.

## Adding a New Provider

### OpenAI-compatible endpoint (most common)

1. Add a preset map in `musician_core/lib/musician_core/config/presets.ex`:
   ```elixir
   "myprovider" => %ProviderConfig{
     api_base: "https://api.myprovider.com/v1",
     model: "my-model-id",
     api_key_env: "MYPROVIDER_API_KEY"
   }
   ```
2. No new module needed — `OpenAICompat` handles `/chat/completions` automatically.
3. Add the provider name to the `@valid_providers` list in `Config.Schema`.
4. Add an E2E test at `apps/musician_core/test/musician_core/provider/myprovider_e2e_test.exs` tagged `@moduletag :provider_e2e`. Follow the pattern in `minimax_e2e_test.exs`: start Finch, skip when env var absent, call `safe_call/1`.

### Custom API (non-OpenAI shape)

1. Create `apps/musician_core/lib/musician_core/provider/my_provider.ex` and implement all three `MusicianCore.Provider.Behaviour` callbacks: `complete/2`, `stream/2`, `list_models/1`.
2. Add a preset as above, plus wire the module in `MusicianCore.Provider.router/1`.
3. Follow the same E2E test conventions.
