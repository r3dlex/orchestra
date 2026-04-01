"""Tests for pipeline_runner.runner."""

from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

from pipeline_runner.models import StepStatus
from pipeline_runner.runner import PipelineRunner, _find_project_root


class TestFindProjectRoot:
    def test_finds_package_json(self, project_root: Path) -> None:
        assert (project_root / "package.json").exists()

    def test_returns_cwd_when_no_package_json(self, tmp_path: Path) -> None:
        # A directory with no package.json anywhere above it
        nested = tmp_path / "a" / "b"
        nested.mkdir(parents=True)
        # walk from nested; hits tmp_path.parent which is usually / or system root
        result = _find_project_root(nested)
        # Should fall back to cwd without raising
        assert isinstance(result, Path)


class TestPipelineRunner:
    def test_init_auto_detects_root(self) -> None:
        runner = PipelineRunner()
        assert (runner.project_root / "package.json").exists()

    def test_init_explicit_cwd(self, project_root: Path) -> None:
        runner = PipelineRunner(cwd=str(project_root))
        assert runner.project_root == project_root

    def test_get_pipeline_valid(self) -> None:
        runner = PipelineRunner()
        pipeline = runner.get_pipeline("test")
        assert pipeline.name == "test"
        assert len(pipeline.steps) > 0

    def test_get_pipeline_unknown_raises(self) -> None:
        runner = PipelineRunner()
        with pytest.raises(ValueError, match="Unknown pipeline"):
            runner.get_pipeline("nonexistent-pipeline")

    def test_run_dry_run_skips_all_steps(self) -> None:
        runner = PipelineRunner()
        result = runner.run("test", dry_run=True)
        assert result.pipeline == "test"
        assert result.status == StepStatus.SUCCESS
        assert all(r.status == StepStatus.SKIPPED for r in result.step_results)

    def test_run_dry_run_ci_pipeline(self) -> None:
        runner = PipelineRunner()
        result = runner.run("ci", dry_run=True)
        assert result.status == StepStatus.SUCCESS
        assert len(result.step_results) == len(runner.get_pipeline("ci").steps)

    def test_run_success_when_all_steps_return_zero(self) -> None:
        runner = PipelineRunner()
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0)
            result = runner.run("test", dry_run=False)
        assert result.status == StepStatus.SUCCESS
        assert all(r.status == StepStatus.SUCCESS for r in result.step_results)

    def test_run_fails_on_nonzero_exit(self) -> None:
        runner = PipelineRunner()
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=1)
            result = runner.run("test", dry_run=False)
        assert result.status == StepStatus.FAILED

    def test_run_stops_after_first_failure(self) -> None:
        runner = PipelineRunner()
        pipeline = runner.get_pipeline("ci")
        assert len(pipeline.steps) > 1, "ci must have multiple steps for this test"

        with patch("subprocess.run") as mock_run:
            # First call fails
            mock_run.return_value = MagicMock(returncode=1)
            result = runner.run("ci", dry_run=False)

        # Only 1 step result — stopped after first failure
        assert len(result.step_results) == 1
        assert result.status == StepStatus.FAILED

    def test_run_handles_command_not_found(self) -> None:
        runner = PipelineRunner()
        with patch("subprocess.run", side_effect=FileNotFoundError("no such file")):
            result = runner.run("test", dry_run=False)
        assert result.status == StepStatus.FAILED
        assert result.step_results[0].returncode == 127

    def test_step_cwd_defaults_to_project_root(self) -> None:
        runner = PipelineRunner()
        from pipeline_runner.models import Step

        step = Step(name="s", command=["echo"])
        assert runner._step_cwd(step) == runner.project_root

    def test_step_cwd_relative_to_project_root(self) -> None:
        runner = PipelineRunner()
        from pipeline_runner.models import Step

        step = Step(name="s", command=["echo"], cwd="tools/pipeline_runner")
        assert runner._step_cwd(step) == runner.project_root / "tools/pipeline_runner"
