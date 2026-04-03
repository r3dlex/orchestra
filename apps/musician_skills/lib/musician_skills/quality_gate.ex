defmodule MusicianSkills.QualityGate do
  @moduledoc "Validate a skill's test suite."

  def validate(skill_path) do
    unless File.dir?(skill_path) do
      {:error, :not_found}
    else
      tests_dir = Path.join(skill_path, "tests")

      if File.dir?(tests_dir) do
        run_tests(tests_dir)
      else
        {:ok, :passed}
      end
    end
  end

  defp run_tests(tests_dir) do
    scripts = File.ls!(tests_dir) |> Enum.filter(&String.ends_with?(&1, ".sh"))

    if Enum.empty?(scripts) do
      {:ok, :passed}
    else
      results =
        Enum.map(scripts, fn script ->
          path = Path.join(tests_dir, script)

          case System.cmd("sh", [path], stderr_to_stdout: true) do
            {_, 0} -> :ok
            {output, code} -> {:fail, script, code, output}
          end
        end)

      failures = Enum.filter(results, &match?({:fail, _, _, _}, &1))
      if Enum.empty?(failures), do: {:ok, :passed}, else: {:error, failures}
    end
  end
end
