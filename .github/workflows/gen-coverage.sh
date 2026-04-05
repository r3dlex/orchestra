#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

# Run per-app tests with coverage (each app's BEAM compiles cleanly, no Mox issue).
# Don't use --export-coverage - we'll use mix test.coverage in same step instead.
TEST_APPS="musician_auth musician_core musician_session orchestra musician_memory musician_tools musician_skills musician_plugins"
for app in $TEST_APPS; do
  echo "Testing $app..."
  MIX_ENV=test mix test "apps/$app" --no-deps-check --cover 2>/dev/null || true
done

echo "Done"
