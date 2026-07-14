<div align="center">
  <img src="assets/musician-logo.svg" width="200" alt="Musician + Orchestra" />

  # Musician + Orchestra

  **A provider-configurable LLM CLI and multi-agent orchestration plugin, built in Elixir.**
</div>

Musician is the CLI and runtime. Orchestra is a plugin that adds team, persistence-loop,
tmux, and worktree building blocks. This repository is currently a source distribution at
version `0.1.0`; it does not publish installable binaries or tagged releases yet.

The repository also contains a recovered snapshot of `@anthropic-ai/claude-code` v2.1.88
under `src/`, `data/`, and `tests/`. That snapshot is read-only reference material, not part
of the Musician build.

## Prerequisites

- Git
- Elixir 1.17 or newer
- Erlang/OTP 27. The locked test dependencies are not currently compatible with OTP 29.
- Provider access for live prompts: an API credential, a Codex device login, or a local
  Ollama server
- Zig 0.13.0 only when building a Burrito release

Node.js 22 and Python 3.12 are used by the recovered-reference tests and repository pipeline
runner. The optional TUI native dependency currently requires Python older than 3.12; the
recommended CLI path below does not build the TUI.

## Quick Start

The recommended first run builds the source checkout and prints the implemented CLI help
without contacting an LLM provider:

```sh
git clone https://github.com/r3dlex/orchestra.git
cd orchestra
cd apps/musician_cli
mix deps.get
mix run -e 'MusicianCli.Cli.main(["--help"])'
```

The CLI help includes:

```text
musician — provider-agnostic LLM CLI
```

That proves the CLI app and its declared dependencies compile and its entrypoint loads. To
check that app after setup, run from the same directory:

```sh
MIX_ENV=test mix deps.get
mix test
```

Success is an exit status of zero with `0 failures`; the exact test count changes as the
project evolves. This focused check is intentionally not a claim that every umbrella app or
provider integration has run.

## Run a Prompt

Configuration is YAML. Musician merges `~/.musician/config.yaml` with
`.musician/config.yaml` in the current directory; local values override global ones. When
neither file defines a `providers` map, Musician uses every built-in preset. A non-empty
`providers` map selects only the named providers and inherits omitted fields from matching
presets.

For example, configure MiniMax in `~/.musician/config.yaml`:

```yaml
default_provider: minimax
providers:
  minimax:
    api_base: https://api.minimaxi.chat/v1
    model: MiniMax-M2.7
    api_key_env: env:MINIMAX_API_KEY
```

Then export the credential and invoke the implemented non-interactive prompt path:

```sh
export MINIMAX_API_KEY='your-key'
mix run -e 'MusicianCli.Cli.main(["--provider", "minimax", "--prompt", "Reply with exactly MUSICIAN_OK"])'
```

A successful provider response prints `MUSICIAN_OK`. API-key-authenticated providers using
the OpenAI-compatible adapter need the `env:` prefix in `api_key_env`; it tells Musician to
read the named environment variable instead of treating the value as a literal credential.
The current MiniMax and Gemini presets use bare names, so override `api_key_env` as shown
above before using either preset. Ollama needs no key, and Codex uses device authentication.
The native Anthropic adapter instead expects a bare environment-variable name, such as
`ANTHROPIC_API_KEY`, and reads that variable directly.

Codex device authentication is available to source checkouts with:

```sh
mix musician.codex.login
```

It stores the resulting token data at `~/.musician/auth/codex.yaml`. The top-level
`musician login` and `musician config` subcommands shown by the CLI are currently stubs.

## Mental Model

```text
Provider adapters + config + auth
                ↓
       Implemented Musician CLI paths

TUI source (integration incomplete)     Orchestra plugin primitives
                                        (team, ralph, tmux, worktrees)

src/ + data/ + tests/  →  read-only Claude Code reference snapshot
```

The active Elixir umbrella lives under `apps/`:

- `musician_core` owns configuration, provider requests, and streaming.
- `musician_auth`, `musician_memory`, `musician_session`, and `musician_skills` own durable
  supporting services.
- `musician_tools` exposes shell, file, and web tools.
- `musician_cli` provides the implemented command entrypoints. The no-argument TUI route
  and `musician_tui` integration are incomplete, so the Quick Start does not rely on them.
- `musician_plugins` defines the plugin API, registry, and hook primitives; runtime plugin
  loading is not wired. `orchestra` provides orchestration primitives.

Orchestra's source currently declares `/orchestra team`, `/orchestra ralph`,
`/orchestra status`, and `/orchestra stop`. Runtime registration and dispatch are not fully
wired, so these names describe the intended plugin surface rather than demonstrated
end-to-end commands.

## Configuration and Managed State

| Path | Owner | Purpose |
| --- | --- | --- |
| `~/.musician/config.yaml` | You | Global configuration |
| `.musician/config.yaml` | You | Project-local configuration overrides |
| `~/.musician/auth/*.yaml` | Musician | Provider tokens; sensitive |
| `~/.musician/memory.db` | Musician schema | Configured SQLite memory path; automatic startup is not fully wired |
| `~/.musician/history.jsonl` | Musician Session library | Default session-history path; the recommended CLI run does not create it |
| `~/.musician/skills/` | You and Musician Skills library | Default installed/generated-skills path; the recommended CLI run does not create it |
| `~/.musician/worktrees/` | Orchestra configuration | Configured default for intended worker worktrees; end-to-end creation is not wired |
| `.musician/worker-*` | Orchestra backend builders | Intended per-worker outputs; end-to-end production is not wired |
| `_build/`, `deps/`, `cover/`, `artifacts/` | Build and test tools | Regenerable project output |
| `.ai/` | AI-SDLC tooling | Repository governance metadata; follow `AGENTS.md` before editing |

The repository does not globally ignore `.musician/`. Review project-local configuration
and worker output before committing. The AI-SDLC block at the end of this README is managed
by repository tooling; preserve its marker comments when editing this file.

## Safety

Musician is development-stage automation software. Its `bash` tool executes commands through
`sh -c`, and its file-write tool can write to the path it receives. There is no tool approval
or filesystem sandbox at those boundaries today.

- Run agents only in trusted, backed-up workspaces and review proposed commands.
- Do not put API keys in YAML. For API-key-authenticated OpenAI-compatible providers, use
  `env:VARIABLE_NAME`; for the native Anthropic adapter, use the bare variable name. `.env`
  files are gitignored.
- Treat `~/.musician/auth/*.yaml`, memory, history, and worker outputs as sensitive.
- Review `git status` before commits, especially after skills or Orchestra workers run.
- Before Orchestra cleanup, inspect every managed worktree and commit or stash its changes;
  cleanup can force-remove a worktree and discard uncommitted files.

Do not paste credentials into public issues. This repository does not currently publish a
separate security-reporting policy.

## Update a Source Checkout

There is currently one supported update path: update the Git checkout and refresh Mix
dependencies.

```sh
set -e
cd "$(git rev-parse --show-toplevel)"
status=$(git status --porcelain) || exit 1
test -z "$status" || { echo 'commit or stash local changes first'; exit 1; }
git pull --ff-only
cd apps/musician_cli
mix deps.get
mix test
```

Because no binary/package release channel exists, instructions that imply an installer,
package-manager upgrade, or downloadable executable are intentionally omitted.

## Troubleshooting

### `elixir` or `mix` is not found

Install Elixir 1.17+ with Erlang/OTP 27, then confirm both are visible:

```sh
elixir --version
mix --version
```

### Ratatouille or `ex_termbox` fails to build

The TUI's transitive `ex_termbox` build is currently incompatible with Python versions that
removed the `imp` module. CI works around this by excluding `musician_tui`. Work app by app
when the TUI is not relevant, for example:

```sh
(cd apps/musician_core && mix deps.get && mix test --no-start --exclude provider_e2e)
(cd apps/orchestra && mix deps.get && mix test --no-start)
```

The TUI is unavailable under that workaround. Zig is unrelated unless you are building a
Burrito release.

### A provider returns an authentication error

For MiniMax and other OpenAI-compatible providers, confirm that `api_key_env` starts with
`env:`. For the native Anthropic adapter, use the bare environment-variable name. In both
cases, confirm that the named variable is exported in the same shell and that the local
`.musician/config.yaml` is not overriding the global provider configuration.

```sh
test -n "$MINIMAX_API_KEY" && echo 'credential is set'
```

Do not print the credential itself. Codex device-flow failures can be retried with
`mix musician.codex.login`; tokens are expected under `~/.musician/auth/`.

### Tests try to contact a real provider

Provider E2E tests require external credentials and are not part of the default confidence
check. Run them deliberately with the relevant environment variable and the
`provider_e2e` tag; see [the testing specification](spec/musician-testing.md).

For known operational failure patterns, see the
[troubleshooting matrix](docs/learning/troubleshooting-matrix.md).

## Advanced Documentation

Start with the active Musician implementation:

- [Architecture and dependency boundaries](spec/musician-architecture.md)
- [Providers, authentication, and streaming](spec/musician-providers.md)
- [CLI, Mix tasks, and Burrito releases](spec/musician-cli.md)
- [Testing strategy and E2E conventions](spec/musician-testing.md)
- [Architecture decision records](.archgate/adrs/)
- [Agent and repository operating guide](AGENTS.md)

The following documents describe the read-only Claude Code reference snapshot, not Musician:

- [Reference architecture](spec/architecture.md)
- [Reference tool system](spec/tools.md)
- [Reference command system](spec/commands.md)
- [Reference state management](spec/state-management.md)
- [Recovery methodology](spec/decompilation.md)

## Contributing and Community

Read [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) before changing the
active Elixir code. Do not modify the recovered `src/`, `data/`, or `tests/` trees.

Use [GitHub Issues](https://github.com/r3dlex/orchestra/issues) for reproducible bugs and
focused feature proposals. Include the failing command, sanitized output, platform, Elixir
version, and OTP version; never include tokens or private prompt/session data.

## License

Musician + Orchestra is available under the [MIT License](LICENSE). The recovered reference
package retains its own notices under `data/package/`.

<!-- v3-ai-sdlc-init:start -->
## AI SDLC v3
This repo follows the v3 AI-SDLC layout. See `.ai/matrix.json`, `.memory/human-override/`, and `docs/architecture/adr/`. Modules at `r3dlex/skills/ai-sdlc-init/modules/`.
<!-- v3-ai-sdlc-init:end -->
