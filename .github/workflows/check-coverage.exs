# Parses _build/coverage/coverage.xml and verifies per-app thresholds.
# Runs standalone via `elixir .github/workflows/check-coverage.exs` — no Mix.
coverage_path = "_build/coverage/coverage.xml"

thresholds = %{
  "musician_memory" => 90,
  "musician_session" => 80,
  "orchestra" => 80,
  "musician_tools" => 80,
  "musician_skills" => 80,
  "musician_plugins" => 85,
  "musician_core" => 95,
  "musician_auth" => 80
}

content = File.read!(coverage_path)

failures =
  for {app, min_pct} <- thresholds, into: [] do
    # Macro.camelize converts "musician_memory" -> "MusicianMemory"
    app_module =
      app
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join()

    pattern = ~r/<package name="Elixir\.#{app_module}"[^>]*line-rate="([0-9.]+)"/

    actual =
      case Regex.run(pattern, content) do
        [_, rate] ->
          (String.to_float(rate) * 100) |> Float.round(1) |> trunc()

        nil ->
          0
      end

    IO.puts("  #{app}: #{actual}% (minimum #{min_pct}%)")

    if actual < min_pct,
      do: {app, min_pct, actual},
      else: nil
  end
  |> Enum.reject(&is_nil/1)

if failures != [] do
  IO.puts("\nCoverage below threshold:")
  for {app, min, actual} <- failures do
    IO.puts("  #{app}: #{actual}% (minimum #{min}%)")
  end

  System.halt(1)
else
  IO.puts("\nAll apps meet coverage thresholds.")
end
