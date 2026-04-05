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
# Use Erlang's :cover directly — erl bypasses Mix so ratatouille deps don't matter.
# .coverdata files from the test run are in _build/test/.
mkdir -p _build/coverage
erl -noshell -eval '
  {ok, files} = file:list_dir("_build/test"),
  CoverdataFiles = [filename:join(["_build/test", F]) || F <- files, filelib:is_file(filename:join(["_build/test", F])) andalso string:suffix(F, ".coverdata")],
  io:format("Found ~p coverdata files~n", [length(CoverdataFiles)]),
  cover:start(),
  [cover:import(F) || F <- CoverdataFiles],
  cover:pmap_write_file("_build/coverage/coverage.xml"),
  io:format("Coverage report written to _build/coverage/coverage.xml~n"),
  init:stop()
'

echo "Done (tests exit: $TEST_EXIT)"
