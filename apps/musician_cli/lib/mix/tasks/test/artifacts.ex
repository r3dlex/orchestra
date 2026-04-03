defmodule MusicianCli.Mix.Tasks.Test.Artifacts do
  use Mix.Task

  @shortdoc "Generate CI proof artifacts"

  @moduledoc """
  Generates CI proof artifacts in the artifacts/ directory.
  """

  @artifacts [
    {"Unit results", "mix test --exclude integration --exclude e2e", nil},
    {"Coverage summary", "mix test --cover --exclude integration --exclude e2e",
     "artifacts/coverage-summary.txt"},
    {"Auth: Codex", "mix test --only auth_codex", "artifacts/e2e/auth-flow-codex.log"},
    {"Provider: MiniMax", "mix test --only provider_e2e", "artifacts/e2e/provider-minimax.log"},
    {"Provider: Claude", "mix test --only claude_e2e", "artifacts/e2e/provider-claude.log"},
    {"Provider: Gemini", "mix test --only gemini_e2e", "artifacts/e2e/provider-gemini.log"},
    {"Skills", "mix test --only skill_e2e", "artifacts/e2e/skill-creation.log"},
    {"Memory", "mix test --only memory_e2e", "artifacts/e2e/memory-crud.log"},
    {"Session", "mix test --only session_e2e", "artifacts/e2e/session-search.log"},
    {"Orchestra: team", "mix test --only team_e2e", "artifacts/e2e/orchestra-team-lifecycle.log"}
  ]

  @impl Mix.Task
  def run(_args) do
    File.mkdir_p!("artifacts/e2e")

    Enum.each(@artifacts, fn {name, cmd, output} ->
      IO.puts("==> #{name}")
      {result, _code} = System.cmd("sh", ["-c", cmd], stderr_to_stdout: true)
      if output, do: File.write!(output, result)
    end)

    IO.puts("==> Artifacts generated in artifacts/")
  end
end
