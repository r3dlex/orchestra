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
# Use Erlang's :cover directly to avoid Mix deps validation (ratatouille excluded).
# The .coverdata files are in _build/test/ after --export-coverage.
mkdir -p _build/coverage
elixir --no-deps-check -e '
:cover.start()

# Import all .coverdata files exported by the test run
coverdata_dir = "_build/test"
output_path = "_build/coverage/coverage.xml"

# Find all .coverdata files
coverdata_files =
  case File.ls(coverdata_dir) do
    {:ok, files} ->
      files
      |> Enum.filter(&String.ends_with?(&1, ".coverdata"))
      |> Enum.map(&Path.join(coverdata_dir, &1))
    _ ->
      []
  end

IO.puts("Found coverdata files: #{length(coverdata_files)}")

# Import each coverdata file
for file <- coverdata_files do
  IO.puts("Importing: #{file}")
  :cover.import(String.to_charlist(file))
end

# Write XML coverage report
:cover.pmap_write_file(String.to_charlist(output_path))
IO.puts("Coverage report written to: #{output_path}")
'

echo "Done (tests exit: $TEST_EXIT)"
