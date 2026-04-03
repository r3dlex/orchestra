# Musician — Testing Strategy

## Test Counts (Phases 1-5)

| App | Tests |
|-----|-------|
| musician_plugins | 16 |
| musician_tui | 18 |
| musician_tools | 22 |
| musician_skills | 7 |
| musician_session | 12 |
| orchestra | 33 |
| musician_core | 37 |
| musician_auth | 21 |
| musician_memory | 17 |
| musician_cli | 1 |
| **Total** | **184** |

## Test Layers

### Unit Tests (default `mix test`)

Standard ExUnit tests. No network. Mock via `Mox` where needed. Run with:

```sh
mix test
mix test apps/musician_core   # single app
```

### E2E / Provider Tests (`@moduletag :provider_e2e`)

Hit real provider APIs. Skipped when env var is absent. Run with:

```sh
MINIMAX_API_KEY=sk-cp-... mix test --only provider_e2e
CODEX_E2E=true mix test --only codex_e2e
```

Tags used:
- `:provider_e2e` — any real-API test
- `:codex_e2e` — Codex device flow specifically (requires `CODEX_E2E=true`)

## Running Specific Test Tags

```sh
# Run all provider E2E tests (requires relevant API keys in env)
MINIMAX_API_KEY=sk-cp-... mix test --only provider_e2e

# Run only Codex E2E tests
CODEX_E2E=true mix test --only codex_e2e

# Run a single app's E2E tests
MINIMAX_API_KEY=sk-cp-... mix test apps/musician_core --only provider_e2e

# Run all unit tests excluding E2E (default behaviour)
mix test

# Run tests for a specific app only
mix test apps/orchestra
```

Tags are declared at module level with `@moduletag :provider_e2e` (or `:codex_e2e`). ExUnit excludes them by default via `ExUnit.configure(exclude: [:provider_e2e, :codex_e2e])` in `test_helper.exs`. Passing `--only <tag>` overrides the exclusion and runs only that tag.

## E2E Test Conventions

1. `async: false` — E2E tests are sequential (shared Finch pool)
2. `import MusicianCore.E2EHelpers` — provides `start_finch/0` and `safe_call/1`
3. `setup do: start_finch()` — starts and unlinks Finch so it survives test case exit
4. Inline skip with `if is_nil(key)` — `ExUnit.skip/1` is private; use `IO.puts` + early return
5. `Enum.to_list(stream)` — fully drain a stream before the test process exits

## E2EHelpers

Located at `apps/musician_core/test/support/e2e_helpers.ex` (compiled in `:test` env via `elixirc_paths/1`).

```elixir
start_finch/0    # Finch.start_link + Process.unlink (prevents pool death on test exit)
safe_call/1      # Retries once after 500ms on :exit (Finch HTTP1 pool recycle)
```

**Critical**: Always call `Process.unlink(pid)` after `Finch.start_link`. Without it, when the test case process exits, the linked Finch process is also killed, causing `NimblePool.checkout shutdown` errors in subsequent tests.

## MiniMax E2E Tests

| File | What it tests |
|------|---------------|
| `minimax_e2e_test.exs` | Basic non-streaming completion |
| `minimax_streaming_e2e_test.exs` | SSE streaming, asserts `length(chunks) >= 1` |
| `minimax_models_e2e_test.exs` | `list_models/1`, handles 404 gracefully (free tier) |
| `minimax_multiturn_e2e_test.exs` | Multi-turn conversation context |

Free-tier note: non-streaming completions return HTTP 500 (`token plan not support model`) on the free MiniMax plan. The streaming endpoint succeeds. Affected tests match `{:error, {:api_error, 500, _}}` and assert true.

## Codex E2E Tests

| File | What it tests |
|------|---------------|
| `codex_device_integration_test.exs` | `request_device_code/0` against real `auth0.openai.com` |
| `codex_completion_e2e_test.exs` | Completion with stored token from `~/.musician/auth/codex.yaml` |

## CI Pipeline

```sh
mix pipeline   # compile + test + credo + dialyzer (defined in musician_cli)
```

GitHub Actions: `.github/workflows/` runs `mix pipeline` on push/PR.
