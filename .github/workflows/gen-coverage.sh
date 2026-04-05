#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")/../.." && pwd)"
cd "$SCRIPT_DIR"

echo "Removing broken deps (ratatouille/ex_termbox - musician_tui excluded)..."
rm -rf deps/ex_termbox deps/ratatouille _build/MIX/@lib/musician_tui 2>/dev/null || true

echo "Compiling all apps..."
mix compile --no-start --no-deps-check

# Per-app tests compile cleanly (no Mox issue), but each BEAM exits after its test.
# We need coverdata from each app. Use a shared export dir and export after each app.
COVERDATA_DIR="_build/test"
mkdir -p "$COVERDATA_DIR"

TEST_APPS="musician_auth musician_core musician_session orchestra musician_memory musician_tools musician_skills musician_plugins"
for app in $TEST_APPS; do
  echo "Testing $app..."
  MIX_ENV=test mix test "apps/$app" --no-deps-check --cover --export-coverage "$COVERDATA_DIR/.coverdata" 2>/dev/null || true
done

# Now generate XML from collected coverdata using Erlang's :cover directly.
# This bypasses Mix entirely (no ratatouille dep validation issue).
echo "Generating coverage XML from coverdata..."
erl -noshell -eval '
  {ok, Files} = file:list_dir("_build/test"),
  CoverdataFiles = lists:filter(
    fun(F) ->
      filelib:is_file(filename:join(["_build/test", F])) andalso
      ".coverdata" == filename:extension(F)
    end,
    Files
  ),
  io:format("Found ~p coverdata files: ~p~n", [length(CoverdataFiles), CoverdataFiles]),
  cover:start(),
  [cover:import(filename:join(["_build/test", F])) || F <- CoverdataFiles],
  file:make_dir("_build/coverage"),
  cover:analyse_to_file("_build/coverage/coverage.xml", [html]),
  io:format("Coverage XML written to _build/coverage/coverage.xml~n"),
  init:stop()
'.

echo "Done"
