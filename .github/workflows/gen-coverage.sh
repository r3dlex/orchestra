#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning broken deps and lock entries..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true
mix lock --remove ratatouille 2>/dev/null || true

echo "Getting dependencies..."
mix deps.get --exclude-apps musician_tui

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

echo "Running per-app tests with coverage..."
rm -rf cover/ _build/test/cover/ 2>/dev/null || true

# Test each app with exclusions
test_app() {
  local app=$1
  shift
  local exclusions="$@"
  echo ""
  echo "=== Testing $app ==="
  if [ -n "$exclusions" ]; then
    (cd "apps/$app" && MIX_ENV=test mix test --no-deps-check --cover --export-coverage "$app" $exclusions)
  else
    (cd "apps/$app" && MIX_ENV=test mix test --no-deps-check --cover --export-coverage "$app")
  fi
}

# musician_core: exclude provider_e2e tests (require external API keys)
test_app "musician_core" "--exclude" "provider_e2e"

# musician_auth: exclude provider_e2e tests (require external API keys + MusicianCore deps)
test_app "musician_auth" "--exclude" "provider_e2e"

# musician_tools: no exclusions needed
test_app "musician_tools"

# musician_skills: no exclusions needed
test_app "musician_skills"

# musician_memory: exclude decay_sweeper_test (flaky timing-based tests)
test_app "musician_memory" "--exclude" "decay_sweeper_test"

# musician_session: no exclusions needed
test_app "musician_session"

# musician_plugins: no exclusions needed
test_app "musician_plugins"

# orchestra: no exclusions needed
test_app "orchestra"

echo ""
echo "Generating coverage XML..."
elixir .github/workflows/gen-coverage-xml.exs

echo "Done."