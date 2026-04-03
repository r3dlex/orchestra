"""Tests for built-in pipeline definitions."""

from __future__ import annotations

from pipeline_runner.pipelines import PIPELINES


class TestBuiltinPipelines:
    def test_required_pipelines_exist(self) -> None:
        for name in ("test", "archgate", "ci", "python-test", "python-lint"):
            assert name in PIPELINES, f"Pipeline '{name}' not found"

    def test_ci_pipeline_has_multiple_steps(self) -> None:
        ci = PIPELINES["ci"]
        assert len(ci.steps) >= 3

    def test_test_pipeline_runs_vitest(self) -> None:
        test = PIPELINES["test"]
        commands = [" ".join(s.command) for s in test.steps]
        assert any("vitest" in c for c in commands)

    def test_archgate_pipeline_runs_archgate(self) -> None:
        ag = PIPELINES["archgate"]
        commands = [" ".join(s.command) for s in ag.steps]
        assert any("archgate" in c for c in commands)

    def test_python_test_pipeline_runs_pytest(self) -> None:
        pt = PIPELINES["python-test"]
        commands = [" ".join(s.command) for s in pt.steps]
        assert any("pytest" in c for c in commands)

    def test_all_pipelines_have_description(self) -> None:
        for name, pipeline in PIPELINES.items():
            assert pipeline.description, f"Pipeline '{name}' has no description"

    def test_all_steps_have_non_empty_command(self) -> None:
        for name, pipeline in PIPELINES.items():
            for step in pipeline.steps:
                assert step.command, f"Pipeline '{name}' step '{step.name}' has empty command"
