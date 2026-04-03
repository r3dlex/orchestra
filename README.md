# musician + orchestra

**Musician** — a provider-agnostic interactive CLI for LLMs, built in Elixir.
**Orchestra** — a multi-agent orchestration plugin on top of Musician.

## Status

**Phases 1-5 complete** — 184 tests, 0 failures.

Foundation, MiniMax streaming, multi-turn, auth (Device Code + PKCE), tools, skills, memory, session, TUI, and Orchestra plugin all ship.

## What Makes This Different

| Feature | Musician + Orchestra | oh-my-claudecode | Hermes-agent |
|---------|---------------------|------------------|--------------|
| Provider-agnostic | ✓ | ✗ (Claude only) | ✓ |
| Self-improving skills | ✓ | ✗ | ✓ |
| Persistent memory | ✓ | ✗ | ✓ |
| Multi-agent orchestration | ✓ (via Orchestra) | ✓ | ✗ |
| Zero-install binary | ✓ (Burrito) | ✗ | ✗ |

## Providers

MiniMax · Claude · Codex · Gemini · Ollama · any OpenAI-compatible endpoint

## Quick Start

```sh
mix deps.get
mix test        # 184 tests, 0 failures
mix pipeline    # full CI
```

Requires Elixir 1.17+, Erlang/OTP 26+. Zig 0.13.0 for binary builds.

## Architecture

See [AGENTS.md](AGENTS.md) for the full project context and agent guide, and [spec/](spec/) for detailed specifications.

Key specs:
- [spec/musician-architecture.md](spec/musician-architecture.md) — Umbrella structure and core abstractions
- [spec/musician-providers.md](spec/musician-providers.md) — Provider system and SSE streaming
- [spec/musician-testing.md](spec/musician-testing.md) — Testing strategy and E2E conventions

ADRs at [.archgate/adrs/](.archgate/adrs/).

## Reference Source

The `src/`, `tests/`, and `data/` directories contain decompiled TypeScript source from `@anthropic-ai/claude-code` v2.1.88, used as reference material for implementation.

## License

See [LICENSE](LICENSE).
