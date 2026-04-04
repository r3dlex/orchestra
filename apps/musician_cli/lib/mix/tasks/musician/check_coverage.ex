defmodule Mix.Tasks.Musician.CheckCoverage do
  @moduledoc """
  Runs each app's tests with coverage and checks that the total coverage
  meets the per-app threshold.
  """
  use Mix.Task

  @app_thresholds %{
    musician_memory: 90,
    musician_session: 80,
    orchestra: 80,
    musician_tools: 80,
    musician_skills: 80,
    musician_plugins: 80,
    musician_core: 80,
    musician_auth: 80,
    musician_cli: 80,
    musician_tui: 80
  }

  @impl true
  def run(_) do
    Mix.shell().info("Running coverage checks for each app...")

    failures =
      for {app, min_pct} <- @app_thresholds, into: [] do
        actual = run_app_coverage_check(app)
        Mix.shell().info("  #{app}: #{actual}% (minimum #{min_pct}%)")
        if actual < min_pct, do: {app, min_pct, actual}, else: nil
      end |> Enum.reject(&is_nil/1)

    if failures != [] do
      Mix.shell().error("\nCoverage below threshold:")
      for {app, min, actual} <- failures do
        Mix.shell().error("  #{app}: #{actual}% (minimum #{min}%)")
      end
      System.halt(1)
    else
      Mix.shell().info("\nAll apps meet coverage thresholds.")
    end
  end

  defp run_app_coverage_check(app) do
    app_path = "apps/#{app}"

    {output, _} =
      System.cmd("mix", ["test", "--cover"],
        cd: app_path,
        stderr_to_stdout: true,
        env: [{"MIX_ENV", "test"}]
      )

    case Regex.run(~r/(\d+(?:\.\d+)?)\s*%\s*\|\s*Total/, output) do
      [_, pct] -> String.to_float(pct) |> trunc()
      nil -> 0
    end
  end
end
