# Musician + Orchestra — AI Agent Guide

This document provides context for AI agents working in this repository.

## What This Is

**Musician** is a provider-agnostic interactive CLI for LLMs built in Elixir.
**Orchestra** is a plugin on top of Musician for multi-agent coordination.

The repo root is the Elixir umbrella project. The `src/`, `tests/`, and `data/` directories contain decompiled claude-code TypeScript source used as reference material only — do not modify them.

## Repository Structure

```
.
├── mix.exs                    # Umbrella root
├── config/config.exs          # Shared config
├── apps/
│   ├── musician_core/         # Config, provider behaviour, HTTP
│   ├── musician_auth/         # API key, Device Code, PKCE
│   ├── musician_tools/        # bash, file_read, file_write, web_fetch
│   ├── musician_skills/       # SKILL.md engine, self-improvement
│   ├── musician_memory/       # SQLite FTS5 persistent memory
│   ├── musician_session/      # JSONL session history + search
│   ├── musician_tui/          # Ratatouille terminal UI
│   ├── musician_cli/          # Binary entrypoint + Mix tasks
│   ├── musician_plugins/      # Plugin registry + hooks
│   └── orchestra/             # Orchestration plugin
├── .archgate/adrs/            # Architecture Decision Records
├── spec/                      # Detailed specifications
├── artifacts/                 # CI-generated proof artifacts
├── src/                       # [READ ONLY] claude-code reference source
├── data/                      # [READ ONLY] claude-code npm package artifacts
└── tests/                     # [READ ONLY] claude-code test suite
```

## Architecture

Provider behaviour is the central abstraction. All LLM providers implement `MusicianCore.Provider.Behaviour`. OpenAI-compatible providers use the shared `OpenAICompat` module. Claude uses the `Anthropic` module for Messages API translation.

Config is YAML everywhere. Global at `~/.musician/config.yaml`, local override at `.musician/config.yaml`.

Auth is centralized at `~/.musician/auth/`. API keys via env var or inline. Codex via Device Code flow.

## Running

```sh
# Install deps
mix deps.get

# Run tests for all apps
mix test

# Run tests for a specific app
mix test apps/musician_core

# Run the full CI pipeline
mix pipeline

# Build Burrito binary (requires Zig 0.13.0)
MIX_ENV=prod mix release musician
```

## Providers

| Provider | Auth | API Style |
|----------|------|-----------|
| MiniMax | API key (MINIMAX_API_KEY) | OpenAI-compat |
| Claude | API key (ANTHROPIC_API_KEY) | Anthropic Messages API |
| Codex | Device Code flow | OpenAI-compat |
| Gemini | API key (GEMINI_API_KEY) | OpenAI-compat |
| Ollama | None | OpenAI-compat |

## Key Decisions (see .archgate/adrs/)

- ARCH-001: Umbrella project structure
- ARCH-002: Provider-agnostic via behaviour + presets
- ARCH-008: Ratatouille for TUI
- ARCH-015: Burrito for zero-install distribution

## v1 Scope

Phase 1 (Weeks 1-4): Foundation + MiniMax streaming
Phase 2 (Weeks 5-8): Multi-provider + tools
Phase 3 (Weeks 9-12): Skills + memory + session
Phase 4 (Weeks 13-16): Orchestra plugin (team + ralph)
Phase 5 (Weeks 17-18): Ship v1.0.0
