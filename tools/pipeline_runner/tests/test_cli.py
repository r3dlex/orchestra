"""Tests for pipeline_runner.cli using Click test runner."""

from __future__ import annotations

from unittest.mock import patch

from click.testing import CliRunner

from pipeline_runner.cli import main
from pipeline_runner.models import PipelineResult, StepStatus


class TestMainGroup:
    def test_help(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["--help"])
        assert result.exit_code == 0
        assert "Pipeline runner" in result.output

    def test_version(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["--version"])
        assert result.exit_code == 0
        assert "0.1.0" in result.output


class TestRunCommand:
    def test_run_unknown_pipeline_exits_1(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["run", "no-such-pipeline"])
        assert result.exit_code == 1
        assert "unknown pipeline" in result.output.lower()

    def test_run_dry_run_exits_0(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["run", "test", "--dry-run"])
        assert result.exit_code == 0

    def test_run_success_exits_0(self) -> None:
        runner = CliRunner()
        mock_result = PipelineResult(pipeline="test", status=StepStatus.SUCCESS)
        with patch("pipeline_runner.cli.PipelineRunner") as mock_cls:
            mock_cls.return_value.run.return_value = mock_result
            result = runner.invoke(main, ["run", "test"])
        assert result.exit_code == 0

    def test_run_failure_exits_1(self) -> None:
        runner = CliRunner()
        mock_result = PipelineResult(pipeline="test", status=StepStatus.FAILED)
        with patch("pipeline_runner.cli.PipelineRunner") as mock_cls:
            mock_cls.return_value.run.return_value = mock_result
            result = runner.invoke(main, ["run", "test"])
        assert result.exit_code == 1

    def test_run_with_cwd_option(self) -> None:
        runner = CliRunner()
        mock_result = PipelineResult(pipeline="test", status=StepStatus.SUCCESS)
        with patch("pipeline_runner.cli.PipelineRunner") as mock_cls:
            mock_cls.return_value.run.return_value = mock_result
            result = runner.invoke(main, ["run", "test", "--cwd", "/tmp"])
        mock_cls.assert_called_once_with(cwd="/tmp")
        assert result.exit_code == 0


class TestListCommand:
    def test_list_shows_all_pipelines(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["list"])
        assert result.exit_code == 0
        for name in ("test", "archgate", "ci"):
            assert name in result.output


class TestInspectCommand:
    def test_inspect_known_pipeline(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["inspect", "test"])
        assert result.exit_code == 0
        assert "test" in result.output.lower()

    def test_inspect_unknown_pipeline_exits_1(self) -> None:
        runner = CliRunner()
        result = runner.invoke(main, ["inspect", "no-such-pipeline"])
        assert result.exit_code == 1
