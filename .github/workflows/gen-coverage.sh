#!/bin/bash

set -x

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

APPS="musician_core musician_auth musician_tools musician_skills musician_memory musician_session musician_plugins orchestra"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running tests with coverage..."
for app in $APPS; do
  echo "  Testing $app..."
  MIX_ENV=test mix test "apps/$app" --no-deps-check --cover --export-coverage "$app"
  result=$?
  echo "  Exit code from $app: $result"
  if [ $result -ne 0 ]; then
    echo "TEST FAILED with exit code $result"
    exit 1
  fi
  echo "  Finished $app"
done

echo "Generating coverage XML..."
pwd
ls -la cover/ 2>/dev/null || echo "No cover/"
ls -la _build/test/cover/ 2>/dev/null || echo "No _build/test/cover/"
find . -name "*.coverdata" 2>/dev/null | head -10
elixir .github/workflows/gen-coverage-xml.exs

echo "Done."
