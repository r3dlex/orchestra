"""Pydantic models for pipeline steps and results."""

from __future__ import annotations

from enum import Enum

from pydantic import BaseModel, Field


class StepStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"


class Step(BaseModel):
    """A single executable step within a pipeline."""

    name: str
    command: list[str]
    cwd: str | None = Field(
        default=None,
        description="Path relative to project root; None means project root.",
    )
    env: dict[str, str] = Field(default_factory=dict)


class Pipeline(BaseModel):
    """An ordered sequence of steps that can be run together."""

    name: str
    description: str
    steps: list[Step]


class StepResult(BaseModel):
    """The outcome of running a single step."""

    step: Step
    status: StepStatus
    returncode: int = 0
    stdout: str = ""
    stderr: str = ""
    duration_ms: int = 0


class PipelineResult(BaseModel):
    """The outcome of running an entire pipeline."""

    pipeline: str
    status: StepStatus
    step_results: list[StepResult] = Field(default_factory=list)
    duration_ms: int = 0
