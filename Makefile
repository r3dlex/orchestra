# Load .env if it exists — vars set here are overridden by command-line args
-include .env
export

.PHONY: all deps test test-e2e test-minimax test-codex codex-login \
        format format-check compile credo pipeline release clean help

# ── Default ──────────────────────────────────────────────────────────────────

all: deps test

# ── Dependencies ─────────────────────────────────────────────────────────────

deps:
	mix deps.get

# ── Tests ─────────────────────────────────────────────────────────────────────

test:
	mix test --no-color

# Requires MINIMAX_API_KEY in .env (or passed on command line)
test-e2e:
	mix test --only provider_e2e --no-color

# MiniMax E2E only
test-minimax:
	mix test apps/musician_core --only provider_e2e --no-color

# Codex E2E — reads stored token from ~/.musician/auth/codex.yaml
# Run `make codex-login` first if you haven't authenticated yet
test-codex:
	CODEX_E2E=true mix test apps/musician_auth --only codex_e2e --no-color

# ── Codex authentication ──────────────────────────────────────────────────────

# Runs the Device Code flow via Elixir and persists tokens to
# ~/.musician/auth/codex.yaml for use by test-codex and the CLI
codex-login:
	mix musician.codex.login

# ── Code quality ──────────────────────────────────────────────────────────────

format:
	mix format

format-check:
	mix format --check-formatted

compile:
	mix compile --warnings-as-errors

credo:
	mix credo --strict

# ── Full CI pipeline ──────────────────────────────────────────────────────────

pipeline:
	mix pipeline

# ── Release ───────────────────────────────────────────────────────────────────

release:
	MIX_ENV=prod mix release musician

# ── Cleanup ───────────────────────────────────────────────────────────────────

clean:
	mix clean
	rm -rf _build deps

# ── Help ──────────────────────────────────────────────────────────────────────

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup"
	@echo "  deps            Install dependencies"
	@echo "  codex-login     Authenticate with Codex (device code flow, stores token)"
	@echo ""
	@echo "Tests"
	@echo "  test            Run unit tests (184 tests)"
	@echo "  test-e2e        Run all provider E2E tests (MINIMAX_API_KEY from .env)"
	@echo "  test-minimax    Run MiniMax E2E tests only"
	@echo "  test-codex      Run Codex E2E tests (requires prior codex-login)"
	@echo ""
	@echo "Code quality"
	@echo "  format          Auto-format code"
	@echo "  format-check    Check formatting (CI mode)"
	@echo "  compile         Compile with warnings-as-errors"
	@echo "  credo           Run Credo strict linter"
	@echo "  pipeline        Run full CI pipeline"
	@echo ""
	@echo "Build & clean"
	@echo "  release         Build Burrito binary (requires Zig 0.13.0)"
	@echo "  clean           Remove build artifacts and deps"
	@echo ""
	@echo "Env vars (set in .env or pass on command line):"
	@echo "  MINIMAX_API_KEY     MiniMax API key (for test-e2e / test-minimax)"
	@echo "  ANTHROPIC_API_KEY   Anthropic API key (for Claude provider)"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make codex-login && make test-codex"
	@echo "  make test-e2e MINIMAX_API_KEY=sk-cp-..."
