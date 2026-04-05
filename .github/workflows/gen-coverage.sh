#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running umbrella tests with coverage..."
# --no-deps-check skips dep validation; ratatouille is removed so it won't block.
# Mox is in :test env and will be loaded when needed.
MIX_ENV=test mix test --no-deps-check --cover --export-coverage default
TEST_EXIT=$?

echo "Generating coverage report..."
# mix test.coverage validates deps (including ratatouille which is excluded).
# Use --no-deps-check to skip validation, running in same BEAM as a task.
MIX_ENV=test mix run --no-deps-check -e 'Mix.Tasks.TestCoverage.run([])'
COVERAGE_EXIT=$?

echo "Done (tests: $TEST_EXIT, coverage: $COVERAGE_EXIT)"
# Exit 0 if tests passed (coverage report failure is non-fatal for now)
exit $TEST_EXIT
