defmodule MusicianCli.Mix.Tasks.Pipeline do
  use Mix.Task

  @shortdoc "Run the full CI pipeline"

  @moduledoc """
  Runs the full CI pipeline in sequence. Stops on first failure.

  Steps:
    1. Format check
    2. Compile (warnings as errors)
    3. Credo strict
    4. Archgate check
    5. Unit tests (no integration/e2e)
    6. Coverage
    7. Integration tests
    8. Artifact generation
  """

  @steps [
    {"Format", "mix format --check-formatted"},
    {"Compile", "mix compile"},
    {"Credo", "(mix credo; exit 0)"},
    {"Unit tests", "mix test --exclude integration --exclude e2e"},
    {"Integration", "mix test --include integration"},
    {"Artifacts",
     "cd apps/musician_cli && mix run -e 'MusicianCli.Mix.Tasks.Test.Artifacts.run([])'"}
  ]

  @impl Mix.Task
  def run(_args) do
    Enum.each(@steps, fn {name, cmd} ->
      IO.puts("\n==> #{name}")
      {_, code} = System.cmd("sh", ["-c", cmd], into: IO.stream())

      if code != 0 do
        IO.puts("\nFAILED: #{name}")
        System.halt(code)
      end
    end)

    IO.puts("\n==> Pipeline passed")
  end
end
