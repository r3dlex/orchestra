defmodule MusicianCli.Mix.Tasks.PipelineTest do
  use ExUnit.Case, async: false

  alias MusicianCli.Mix.Tasks.Pipeline

  describe "run/1" do
    test "prints pipeline step names and succeeds when all steps return 0" do
      try do
        :meck.new(System, [:unstick, :passthrough])
        :meck.expect(System, :cmd, fn "sh", ["-c", _cmd], _opts -> {"ok", 0} end)
        :meck.expect(System, :halt, fn _ -> :ok end)

        output =
          ExUnit.CaptureIO.capture_io(fn ->
            Pipeline.run([])
          end)

        assert output =~ "==> Format"
        assert output =~ "==> Compile"
        assert output =~ "==> Credo"
        assert output =~ "==> Unit tests"
        assert output =~ "==> Integration"
        assert output =~ "==> Artifacts"
        assert output =~ "Pipeline passed"
      after
        :meck.unload(System)
      end
    end

    test "halts with the failing step's exit code when a step fails" do
      try do
        :meck.new(System, [:unstick, :passthrough])

        # Credo fails with exit 127; format/compile/unit/integration/artifacts all succeed
        meck_expect = fn
          "sh", ["-c", "mix format --check-formatted"], _opts -> {"ok", 0}
          "sh", ["-c", "mix compile"], _opts -> {"ok", 0}
          "sh", ["-c", "(mix credo; exit 0)"], _opts -> {"ok", 127}
          "sh", ["-c", _cmd], _opts -> {"ok", 0}
        end

        :meck.expect(System, :cmd, meck_expect)

        :meck.expect(System, :halt, fn code ->
          send(self(), {:halt_called, code})
          :ok
        end)

        output =
          ExUnit.CaptureIO.capture_io(fn ->
            Pipeline.run([])
          end)

        assert output =~ "==> Format"
        assert output =~ "==> Compile"
        assert output =~ "FAILED: Credo"
        assert_received {:halt_called, 127}
      after
        :meck.unload(System)
      end
    end
  end
end
