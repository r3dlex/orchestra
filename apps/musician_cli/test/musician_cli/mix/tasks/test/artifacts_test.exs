defmodule MusicianCli.Mix.Tasks.Test.ArtifactsTest do
  use ExUnit.Case, async: false

  alias MusicianCli.Mix.Tasks.Test.Artifacts

  describe "run/1" do
    test "creates the artifacts/e2e directory" do
      tmp_artifacts =
        Path.join(System.tmp_dir(), "musician_test_artifacts_#{:rand.uniform(999_999)}")

      File.mkdir_p!(tmp_artifacts)

      # Patch the artifact output paths so we write to a temp location.
      _original_module = Artifacts.module_info(:exports)

      # Mock System.cmd to return a fake result string without running real tests.
      :meck.new(System, [:unstick, :passthrough])

      :meck.expect(System, :cmd, fn "sh", ["-c", _cmd], _opts ->
        {"Excluded: 0 | Failed: 0\n", 0}
      end)

      on_exit(fn ->
        try do
          :meck.unload(System)
        catch
          :error, _ -> :ok
        end
      end)

      # Override the working directory for the duration of this test.
      original_dir = File.cwd!()

      try do
        File.cd!(tmp_artifacts)

        output =
          ExUnit.CaptureIO.capture_io(fn ->
            Artifacts.run([])
          end)

        assert File.dir?(tmp_artifacts)
        assert output =~ "==> Unit results"
        assert output =~ "==> Coverage summary"
        assert output =~ "Artifacts generated"
      after
        File.cd!(original_dir)
        File.rm_rf!(tmp_artifacts)
      end
    end

    test "writes artifact file when output path is provided" do
      tmp_dir =
        Path.join(System.tmp_dir(), "musician_test_artifact_write_#{:rand.uniform(999_999)}")

      File.mkdir_p!(tmp_dir)
      _artifact_path = Path.join(tmp_dir, "artifacts/e2e/coverage-summary.txt")

      _original_artifacts = Artifacts.module_info(:exports)

      :meck.new(System, [:unstick, :passthrough])

      :meck.expect(System, :cmd, fn "sh", ["-c", "mix test --cover" <> _], _opts ->
        {"Coverage: 85.0%", 0}
      end)

      :meck.expect(System, :cmd, fn "sh", ["-c", _cmd], _opts ->
        {"Excluded: 0 | Failed: 0\n", 0}
      end)

      on_exit(fn ->
        try do
          :meck.unload(System)
        catch
          :error, _ -> :ok
        end
      end)

      original_dir = File.cwd!()

      try do
        File.cd!(tmp_dir)

        output =
          ExUnit.CaptureIO.capture_io(fn ->
            Artifacts.run([])
          end)

        assert output =~ "Artifacts generated"
      after
        File.cd!(original_dir)
        File.rm_rf!(tmp_dir)
      end
    end
  end
end
