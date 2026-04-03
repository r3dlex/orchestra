.PHONY: all deps test test-e2e test-minimax test-codex pipeline \
        format format-check compile credo release clean help

MINIMAX_API_KEY ?=
CODEX_E2E      ?=

# ── Default ──────────────────────────────────────────────────────────────────

all: deps test

# ── Dependencies ─────────────────────────────────────────────────────────────

deps:
	mix deps.get

# ── Tests ─────────────────────────────────────────────────────────────────────

test:
	mix test --no-color

test-e2e:
	MINIMAX_API_KEY=$(MINIMAX_API_KEY) mix test --only provider_e2e --no-color

test-minimax:
	MINIMAX_API_KEY=$(MINIMAX_API_KEY) \
	  mix test apps/musician_core --only provider_e2e --no-color

test-codex:
	CODEX_E2E=true mix test apps/musician_auth --only codex_e2e --no-color

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
	@echo "  deps            Install dependencies"
	@echo "  test            Run unit tests (184 tests)"
	@echo "  test-e2e        Run provider E2E tests (requires MINIMAX_API_KEY)"
	@echo "  test-minimax    Run MiniMax E2E tests only"
	@echo "  test-codex      Run Codex device flow E2E tests"
	@echo "  format          Auto-format code"
	@echo "  format-check    Check formatting (CI mode)"
	@echo "  compile         Compile with warnings-as-errors"
	@echo "  credo           Run Credo strict linter"
	@echo "  pipeline        Run full CI pipeline (mix pipeline)"
	@echo "  release         Build Burrito binary (requires Zig 0.13.0)"
	@echo "  clean           Remove build artifacts and deps"
	@echo ""
	@echo "Examples:"
	@echo "  make test"
	@echo "  make test-e2e MINIMAX_API_KEY=sk-cp-..."
