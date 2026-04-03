# Musician + Orchestra — Architecture

## Umbrella Structure

```
apps/
├── musician_core/     # Config schema, provider behaviour, HTTP client
├── musician_auth/     # API key store, Device Code flow, PKCE, token store
├── musician_tools/    # Tool implementations (bash, file_read, file_write, web_fetch)
├── musician_skills/   # SKILL.md engine, skill registry, self-improvement loop
├── musician_memory/   # SQLite FTS5 persistent memory store
├── musician_session/  # JSONL session history, replay, search
├── musician_tui/      # Ratatouille terminal UI
├── musician_cli/      # Burrito binary entrypoint, Mix tasks (pipeline, bench)
├── musician_plugins/  # Plugin registry, hook system, lifecycle
└── orchestra/         # Multi-agent orchestration plugin
```

## Dependency Graph

```
musician_cli
  └── musician_tui
        └── orchestra
              └── musician_plugins, musician_tools, musician_skills, musician_session, musician_memory
                    └── musician_auth
                          └── musician_core
```

All apps share `musician_core` at the bottom. `musician_plugins` sits alongside the other middleware apps under `orchestra`. No circular deps.

## Core Abstractions

### Provider Behaviour (`musician_core`)

```elixir
defmodule MusicianCore.Provider.Behaviour do
  @callback complete(ProviderConfig.t(), Request.t()) :: {:ok, Response.t()} | {:error, term()}
  @callback stream(ProviderConfig.t(), Request.t()) :: {:ok, Enumerable.t()} | {:error, term()}
  @callback list_models(ProviderConfig.t()) :: {:ok, [String.t()]} | {:error, term()}
end
```

Two concrete implementations:
- `OpenAICompat` — for MiniMax, Codex, Gemini, Ollama (any `/chat/completions` endpoint)
- `Anthropic` — for Claude (Messages API with role translation)

### Config (`musician_core`)

YAML-based. Global: `~/.musician/config.yaml`. Local override: `.musician/config.yaml`.
Config schema validated with `ProviderConfig` struct. `api_key_env` holds the env var name, never the raw key.

### Auth (`musician_auth`)

- `ApiKey` — reads from env var via `System.get_env/1`
- `CodexDevice` — Device Code OAuth2 flow against `auth0.openai.com`
- `TokenStore` — reads/writes `~/.musician/auth/{provider}.yaml`
- `PKCE` — PKCE helper for authorization code flows

### SSE Streaming (`musician_core`)

`stream/2` in `OpenAICompat` uses `Req.post/2` with an `into:` callback and a background `Task` that sends chunks via message passing to a `Stream.resource`. Parsed by `SSEParser.parse_chunk/1` which splits on `\n\n`, filters `data:` lines, skips `[DONE]`.

## SSE Streaming Architecture

The streaming path uses a Task + Req + Stream pipeline:

```
caller
  │  calls stream/2
  ▼
Task.start/1          ← spawns a background process
  │  Req.post with into: callback
  │    each HTTP chunk → send(parent, {ref, {:data, chunk}})
  │  on finish        → send(parent, {ref, :done})
  ▼
Stream.resource/3     ← pulls from the mailbox
  │  receive {^ref, {:data, chunk}} → SSEParser.parse_chunk/1 → [delta_text, ...]
  │  receive {^ref, :done}          → halt
  │  after 30_000                   → halt (timeout guard)
  ▼
caller receives Enumerable of decoded delta strings
```

Key properties:
- The `Task` is unlinked from the caller; crashes do not propagate.
- `30_000 ms` receive timeout in `Stream.resource` mirrors `Req`'s `receive_timeout`.
- `SSEParser` is pure (no side effects), making it independently testable.
- The same pattern is reused for every OpenAI-compat provider (MiniMax, Codex, Gemini, Ollama).

## Configuration

```yaml
# ~/.musician/config.yaml
provider: minimax
providers:
  minimax:
    api_base: https://api.minimaxi.chat/v1
    model: MiniMax-Text-01
    api_key_env: MINIMAX_API_KEY
```

## Key ADRs (see `.archgate/adrs/`)

| ID | Decision |
|----|----------|
| ARCH-001 | Elixir umbrella for isolation between concerns |
| ARCH-002 | Provider-agnostic via behaviour + presets |
| ARCH-008 | Ratatouille for TUI (not Ink/React) |
| ARCH-015 | Burrito for zero-install binary distribution |
