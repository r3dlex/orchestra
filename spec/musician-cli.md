# Musician CLI — Entry Point & Mix Tasks

## Overview

`musician_cli` is the application that produces the published Musician binary. It handles argument parsing, subcommand dispatch, Mix task definitions, and Burrito release assembly. It has no long-running workers — the OTP application starts an empty supervisor.

## Cli Module

`MusicianCli.Cli.main/1` is the binary entrypoint. It uses `OptionParser` to parse CLI arguments.

### Supported Flags

| Flag | Alias | Type | Description |
|------|-------|------|-------------|
| `--provider` | `-p` | string | Provider name (`minimax`, `claude`, `codex`, `gemini`, `ollama`) |
| `--prompt` | — | string | Run a single non-interactive prompt |
| `--non-interactive` | — | boolean | Disable TUI, write to stdout |
| `--output-file` | — | string | Write response to a file |
| `--help` | `-h` | boolean | Show help text |

### Subcommands

| Command | Status | Description |
|--------|--------|-------------|
| `login` | stub | Authenticate with a provider |
| `config` | stub | Show or edit configuration |
| `help` | implemented | Show help text |
| *(none)* | starts TUI | Launch the Ratatouille TUI |

### Help Output

```
musician — provider-agnostic LLM CLI

Usage:
  musician [options]
  musician <command>

Options:
  --provider, -p <name>   Provider to use (minimax, claude, codex, gemini, ollama)
  --prompt <text>         Run a single prompt (non-interactive)
  --non-interactive       Disable TUI, output to stdout
  --output-file <path>    Write response to file
  --help, -h              Show this help

Commands:
  login     Authenticate with a provider
  config    Show or edit configuration
  help      Show this help
```

## Mix Tasks

### `mix pipeline`

Runs the full CI pipeline in sequence, stopping on first failure.

**Steps:**
1. Format check (`mix format --check-formatted`)
2. Compile with warnings as errors (`mix compile --warnings-as-errors`)
3. Credo strict (`mix credo --strict`)
4. Archgate check (`npx archgate check`)
5. Unit tests (`mix test --exclude integration --exclude e2e`)
6. Coverage (`mix test --cover --exclude integration --exclude e2e`)
7. Integration tests (`mix test --only integration`)
8. Artifact generation (`mix test.artifacts`)

### `mix test.artifacts`

Generates CI proof artifacts in `artifacts/`:

| Artifact | Command | Output file |
|---------|---------|------------|
| Unit results | `mix test --exclude integration --exclude e2e` | (stdout only) |
| Coverage summary | `mix test --cover --exclude integration --exclude e2e` | `artifacts/coverage-summary.txt` |
| Auth: Codex | `mix test --only auth_codex` | `artifacts/e2e/auth-flow-codex.log` |
| Provider: MiniMax | `mix test --only provider_e2e` | `artifacts/e2e/provider-minimax.log` |
| Provider: Claude | `mix test --only claude_e2e` | `artifacts/e2e/provider-claude.log` |
| Provider: Gemini | `mix test --only gemini_e2e` | `artifacts/e2e/provider-gemini.log` |
| Skills | `mix test --only skill_e2e` | `artifacts/e2e/skill-creation.log` |
| Memory | `mix test --only memory_e2e` | `artifacts/e2e/memory-crud.log` |
| Session | `mix test --only session_e2e` | `artifacts/e2e/session-search.log` |
| Orchestra: team | `mix test --only team_e2e` | `artifacts/e2e/orchestra-team-lifecycle.log` |

### `mix musician.codex.login`

Full device code authentication flow for Codex:

1. Requests a device code from `auth0.openai.com/oauth/device/code`
2. Displays the user code and verification URI
3. Polls `auth0.openai.com/oauth/token` until the user approves or the code expires
4. Stores the access token in `~/.musician/auth/codex.yaml` via `MusicianAuth.TokenStore`

Usage:
```sh
mix musician.codex.login
```

Requires browser access on the same machine. Tokens are persisted to `~/.musician/auth/codex.yaml` for use by E2E tests and the CLI.

## Application Module

`MusicianCli.Application` starts an empty supervisor with `strategy: :one_for_one`. No workers are started at runtime — the application exists purely to host the Mix tasks and CLI entrypoint.

## Environment Variables

| Variable | Provider | Used by |
|----------|----------|---------|
| `MINIMAX_API_KEY` | MiniMax | `test-e2e`, E2E tests |
| `ANTHROPIC_API_KEY` | Claude | E2E tests |
| `GEMINI_API_KEY` | Gemini | E2E tests |
| `CODEX_E2E` | Codex | Codex E2E test tag |

All keys are read from environment variables only — never hardcoded. The `.env.example` file in the repo root documents all supported variables.

## .env Support

The Makefile includes `.env` automatically:

```makefile
-include .env
export
```

Set API keys in `.env` (gitignored) for local E2E test runs:

```sh
MINIMAX_API_KEY=sk-cp-... make test-e2e
make codex-login          # stores token in ~/.musician/auth/codex.yaml
make test-codex
```
