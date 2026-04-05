#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running umbrella tests with coverage..."
MIX_ENV=test mix test --no-deps-check --cover --export-coverage default
TEST_EXIT=$?

echo "Generating coverage report..."
escript .github/workflows/gen-coverage.erl

echo "Done (tests exit: $TEST_EXIT)"
