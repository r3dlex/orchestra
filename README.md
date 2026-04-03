# musician + orchestra

**Musician** — a provider-agnostic interactive CLI for LLMs, built in Elixir.
**Orchestra** — a multi-agent orchestration plugin on top of Musician.

## What Makes This Different

| Feature | Musician + Orchestra | oh-my-claudecode | Hermes-agent |
|---------|---------------------|------------------|--------------|
| Provider-agnostic | ✓ | ✗ (Claude only) | ✓ |
| Self-improving skills | ✓ | ✗ | ✓ |
| Persistent memory | ✓ | ✗ | ✓ |
| Multi-agent orchestration | ✓ (via Orchestra) | ✓ | ✗ |
| Zero-install binary | ✓ (Burrito) | ✗ | ✗ |

## Status

**Phase 1 in progress** — Foundation + MiniMax (Weeks 1-4).

## Quick Start

```sh
# Coming with v1.0.0 release
# musician --provider minimax --prompt "Hello"
```

## Providers

MiniMax · Claude · Codex · Gemini · Ollama · any OpenAI-compatible endpoint

## Reference Source

The `src/`, `tests/`, and `data/` directories contain decompiled TypeScript source from `@anthropic-ai/claude-code` v2.1.88, used as reference material for implementation. See the original [README sections below](#reference-source-detail) for details.

---

## Development

```sh
mix deps.get
mix test
mix pipeline   # full CI
```

Requires Elixir 1.17+, Erlang/OTP 26+. Zig 0.13.0 for binary builds.

## Architecture

See [MUSICIAN.md](MUSICIAN.md) for the full agent guide and [.archgate/adrs/](.archgate/adrs/) for architecture decisions.

## License

See [LICENSE](LICENSE).
