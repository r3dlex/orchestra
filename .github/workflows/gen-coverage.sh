#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running umbrella tests with coverage..."
# Run tests and generate coverage XML in one pass
MIX_ENV=test mix test --no-deps-check --cover --export-coverage default
TEST_EXIT=$?

echo "Generating coverage report..."
# Generate XML using mix test.coverage which runs in the same BEAM after tests
# The --no-deps-check helps but the test.coverage task itself still validates
# So we generate our own XML using the test.coverage task format
mix test.coverage 2>/dev/null || true

echo "Done (tests exit: $TEST_EXIT)"