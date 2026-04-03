# AGENTS.md — Project Context & Agent Guide

This repository has two layers:

1. **Musician + Orchestra** — an active Elixir project (the primary codebase under `apps/`)
2. **claude-code reference** — decompiled TypeScript source from `@anthropic-ai/claude-code` v2.1.88, used as read-only reference material (`src/`, `data/`, `tests/`)

---

## Musician + Orchestra

**Musician** is a provider-agnostic interactive CLI for LLMs built in Elixir.
**Orchestra** is a multi-agent orchestration plugin on top of Musician.

### Quick Start

```sh
mix deps.get
mix test                          # 184 tests, 0 failures (Phases 1-5 complete)
mix test apps/musician_core       # single app
mix pipeline                      # full CI (compile + test + credo + dialyzer)

# E2E tests against real providers
MINIMAX_API_KEY=sk-cp-... mix test --only provider_e2e
```

### Repository Layout

```
.
├── mix.exs                    # Umbrella root
├── config/config.exs          # Shared config
├── apps/
│   ├── musician_core/         # Config schema, provider behaviour, HTTP client
│   ├── musician_auth/         # API key store, Device Code, PKCE, token store
│   ├── musician_tools/        # bash, file_read, file_write, web_fetch tools
│   ├── musician_skills/       # SKILL.md engine, self-improvement loop
│   ├── musician_memory/       # SQLite FTS5 persistent memory
│   ├── musician_session/      # JSONL session history + search
│   ├── musician_tui/          # Ratatouille terminal UI
│   ├── musician_cli/          # Burrito binary entrypoint, Mix tasks
│   ├── musician_plugins/      # Plugin registry + hooks
│   └── orchestra/             # Orchestration plugin
├── spec/
│   ├── musician-architecture.md  # Umbrella apps, deps, core abstractions
│   ├── musician-providers.md     # Provider behaviour, OpenAI compat, SSE, auth
│   ├── musician-testing.md       # Unit + E2E test strategy, MiniMax, Codex
│   ├── architecture.md           # [ref] claude-code system architecture
│   ├── tools.md                  # [ref] claude-code tool system spec
│   ├── commands.md               # [ref] claude-code command system spec
│   ├── state-management.md       # [ref] claude-code state management
│   └── decompilation.md          # [ref] decompilation methodology
├── .archgate/adrs/            # Architecture Decision Records
├── artifacts/                 # CI-generated proof artifacts
├── src/                       # [READ ONLY] claude-code reference source (1,902 files)
├── data/                      # [READ ONLY] claude-code npm package artifacts
├── tests/                     # [READ ONLY] claude-code test suite
├── AGENTS.md                  # This file
├── CLAUDE.md                  # Points here
├── MUSICIAN.md                # Musician agent quick-reference
└── README.md                  # Repository overview
```

### Musician Spec References

- **[spec/musician-architecture.md](spec/musician-architecture.md)** — Umbrella structure, dependency graph, core abstractions
- **[spec/musician-providers.md](spec/musician-providers.md)** — Provider behaviour, OpenAI compat, SSE streaming, Codex device flow
- **[spec/musician-testing.md](spec/musician-testing.md)** — Unit + E2E testing strategy, conventions, known free-tier quirks

### Conventions

- Elixir 1.17+, Erlang/OTP 26+, Zig 0.13.0 (binary builds only)
- YAML config everywhere; global `~/.musician/config.yaml`, local `.musician/config.yaml`
- API keys always via env var (`api_key_env` field), never hardcoded
- E2E tests tagged `@moduletag :provider_e2e`, `async: false`, skip inline when key absent
- `Process.unlink(pid)` required after `Finch.start_link` in shared test pools

---

## claude-code Reference Source

The `src/`, `tests/`, and `data/` directories contain a **lossless recovery** of the `@anthropic-ai/claude-code` TypeScript source (v2.1.88) from its embedded source map. Do not modify these directories.

### What Was Recovered

- 1,902 TypeScript source files in `src/`
- Source Map v3 with 4,756 embedded sources at `data/package/cli.js.map`
- Public SDK type definitions at `data/package/sdk-tools.d.ts`

### Reference Structure

```
src/
├── entrypoints/       # Bootstrap (cli.tsx, mcp.ts, sdk/)
├── main.tsx           # Core initialization (~4,600 lines)
├── tools.ts           # Tool registry factory
├── commands.ts        # Command registry
├── query.ts           # Claude API loop
├── tools/             # 184 tool implementations
├── commands/          # 207 command implementations
├── components/        # 389 React/Ink UI components
├── hooks/             # 104 React hooks
├── services/          # 130 service modules
├── utils/             # 564 utility modules
└── state/             # Global state (Zustand-like)
```

### Entry Point Chain

1. `cli.tsx` — fast-path dispatch (version, bridge, MCP, worktree)
2. `main.tsx` — full initialization (settings, auth, plugins, MCP, tools, commands)
3. `REPL.tsx` — interactive terminal UI (Ink/React)
4. `query.ts` — Claude API loop (messages → tool calls → results → repeat)

### Core Abstractions

| Abstraction | Location | Count | Description |
|-------------|----------|-------|-------------|
| Tools | `tools/` | 184 | Model-invocable actions (Bash, File ops, Web, Agent) |
| Commands | `commands/` | 207 | User slash commands |
| Components | `components/` | 389 | Terminal UI (React/Ink) |
| Hooks | `hooks/` | 104 | React state/effect hooks |
| Services | `services/` | 130 | Business logic (MCP, API, analytics) |
| Utils | `utils/` | 564 | Shared utilities |

### Key Systems

- **Permission System** — Mode-based (default/auto/bypass/plan) + rule-based (allow/deny/ask)
- **MCP Integration** — StdIO transport; tools, resources, commands
- **Plugin System** — Marketplace-based installation and management
- **Skill System** — Builtin + bundled + plugin skills with forking
- **State Store** — Centralized Zustand-like store with immutable snapshots

### claude-code Spec References

- **[spec/architecture.md](spec/architecture.md)** — System architecture and module organization
- **[spec/tools.md](spec/tools.md)** — Tool system specification (inputs, outputs, registry)
- **[spec/commands.md](spec/commands.md)** — Command system specification
- **[spec/state-management.md](spec/state-management.md)** — State management patterns
- **[spec/decompilation.md](spec/decompilation.md)** — Decompilation methodology and results

### Agent Guidance for claude-code Reference

- Start with `src/entrypoints/cli.tsx` for the bootstrap flow
- Read `src/main.tsx` for full initialization sequence
- `data/package/sdk-tools.d.ts` has the complete public API surface
- Tool inputs use Zod schemas; `inputJSONSchema` exposes JSON Schema
- Variable names are mangled in `data/package/cli.js` but original in source map
- Tests in `tests/` cover public API types and recovered utility functions: `npm test`

### Technical Notes

- Source is **read-only reference** — cannot be rebuilt without the full Anthropic build system
- Recovery is **lossless** (source map contains complete source content, not heuristic)
- Some files reference internal Anthropic infrastructure (telemetry, feature flags) not publicly accessible
- `data/package/vendor/` contains pre-built native binaries (ripgrep, audio-capture) for multiple platforms
- Built with Bun bundler; single ESM output (`"type": "module"`); Node.js >= 18 required
