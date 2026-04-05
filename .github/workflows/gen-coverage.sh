#!/bin/bash

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
  MIX_ENV=test mix test "apps/$app" --no-deps-check --cover --export-coverage "$app" || true
done

echo "Generating coverage XML..."
MIX_ENV=test elixir -e "
  :cover.start()

  for app <- ~w[musician_core musician_auth musician_tools musician_skills musician_memory musician_session musician_plugins orchestra]a do
    coverdata = \"cover/#{app}.coverdata\"
    if File.exists?(coverdata) do
      :cover.import(String.to_charlist(coverdata))
    end
  end

  modules = :cover.modules()

  packages = for mod <- modules do
    {:ok, coverage} = :cover.analyse(mod, :coverage, :line)
    {_, _, _, {covered, not_covered}} = coverage
    total = covered + not_covered
    rate = if total > 0, do: covered / total, else: 0.0
    package_name = \"Elixir.\" <> (mod |> Module.split() |> Enum.join(\".\"))
    ~s(<package name=\"#{package_name}\" line-rate=\"#{Float.round(rate, 4)}\" branches-covered=\"#{covered}\" branches-uncovered=\"#{not_covered}\" complexity=\"0\">\n  <type name=\"% All Types\" line-rate=\"#{Float.round(rate, 4)}\" branches-covered=\"#{covered}\" branches-uncovered=\"#{not_covered}\" complexity=\"0\"/>\n</package>)
  end |> Enum.join(\"\n\")

  xml = ~s[<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<coverage version=\"5\" timestamp=\"#{:os.system_time(:second)}\" privacy=\"false\" merger=\"coveralls\">\n<packages>\n#{packages}\n</packages>\n</coverage>]
  File.mkdir_p!(\"../_build/coverage\")
  File.write!(\"../_build/coverage/coverage.xml\", xml)
  IO.puts(\"Generated ../_build/coverage/coverage.xml with #{length(modules)} modules\")
"

echo "Done."
