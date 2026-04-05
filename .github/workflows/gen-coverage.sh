#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running umbrella tests with coverage..."
rm -rf cover/ _build/test/cover/ 2>/dev/null || true
MIX_ENV=test mix test --no-deps-check --cover

echo "Generating coverage XML..."
elixir .github/workflows/gen-coverage-xml.exs

echo "Done."
