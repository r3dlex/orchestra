"""Tests for pipeline_runner.models."""

from __future__ import annotations

from pipeline_runner.models import Pipeline, PipelineResult, Step, StepResult, StepStatus


class TestStep:
    def test_defaults(self) -> None:
        step = Step(name="my step", command=["echo", "hi"])
        assert step.cwd is None
        assert step.env == {}

    def test_with_cwd(self) -> None:
        step = Step(name="s", command=["npm", "ci"], cwd="tools/pipeline_runner")
        assert step.cwd == "tools/pipeline_runner"

    def test_with_env(self) -> None:
        step = Step(name="s", command=["env"], env={"FOO": "bar"})
        assert step.env["FOO"] == "bar"


class TestPipeline:
    def test_basic_pipeline(self) -> None:
        p = Pipeline(
            name="test",
            description="run tests",
            steps=[Step(name="step1", command=["echo"])],
        )
        assert p.name == "test"
        assert len(p.steps) == 1


class TestStepResult:
    def test_defaults(self) -> None:
        step = Step(name="s", command=["echo"])
        r = StepResult(step=step, status=StepStatus.SUCCESS)
        assert r.returncode == 0
        assert r.stdout == ""
        assert r.stderr == ""
        assert r.duration_ms == 0

    def test_failed_result(self) -> None:
        step = Step(name="s", command=["false"])
        r = StepResult(step=step, status=StepStatus.FAILED, returncode=1, stderr="oops")
        assert r.status == StepStatus.FAILED
        assert r.returncode == 1


class TestPipelineResult:
    def test_defaults(self) -> None:
        r = PipelineResult(pipeline="ci", status=StepStatus.SUCCESS)
        assert r.step_results == []
        assert r.duration_ms == 0

    def test_with_steps(self) -> None:
        step = Step(name="s", command=["echo"])
        sr = StepResult(step=step, status=StepStatus.SUCCESS)
        r = PipelineResult(pipeline="ci", status=StepStatus.SUCCESS, step_results=[sr])
        assert len(r.step_results) == 1


class TestStepStatus:
    def test_values(self) -> None:
        assert StepStatus.SUCCESS == "success"
        assert StepStatus.FAILED == "failed"
        assert StepStatus.SKIPPED == "skipped"
        assert StepStatus.PENDING == "pending"
        assert StepStatus.RUNNING == "running"
