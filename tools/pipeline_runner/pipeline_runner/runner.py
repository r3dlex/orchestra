"""Core pipeline runner logic."""

from __future__ import annotations

import os
import subprocess
import time
from pathlib import Path

from rich.console import Console
from rich.panel import Panel
from rich.text import Text

from .models import Pipeline, PipelineResult, Step, StepResult, StepStatus
from .pipelines import PIPELINES

console = Console()


def _find_project_root(start: Path) -> Path:
    """Walk up from *start* until a directory containing ``package.json`` is found."""
    current = start.resolve()
    while current != current.parent:
        if (current / "package.json").exists():
            return current
        current = current.parent
    return Path.cwd()


class PipelineRunner:
    """Discovers the project root and executes pipelines step-by-step."""

    def __init__(self, cwd: str | None = None) -> None:
        if cwd:
            self.project_root = Path(cwd).resolve()
        else:
            self.project_root = _find_project_root(Path(__file__).parent)

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_pipeline(self, name: str) -> Pipeline:
        if name not in PIPELINES:
            available = ", ".join(PIPELINES)
            raise ValueError(f"Unknown pipeline '{name}'. Available: {available}")
        return PIPELINES[name]

    def run(self, pipeline_name: str, *, dry_run: bool = False) -> PipelineResult:
        """Run *pipeline_name*, returning a :class:`PipelineResult`."""
        pipeline = self.get_pipeline(pipeline_name)

        console.print(
            Panel(
                f"[bold]{pipeline.description}[/bold]",
                title=f"[cyan]Pipeline: {pipeline.name}[/cyan]",
                expand=False,
            )
        )

        overall_start = time.monotonic()
        step_results: list[StepResult] = []
        overall_status = StepStatus.SUCCESS

        for step in pipeline.steps:
            result = self._run_step(step, dry_run=dry_run)
            step_results.append(result)
            if result.status == StepStatus.FAILED:
                overall_status = StepStatus.FAILED
                break  # fail fast

        duration_ms = int((time.monotonic() - overall_start) * 1000)

        pipeline_result = PipelineResult(
            pipeline=pipeline_name,
            status=overall_status,
            step_results=step_results,
            duration_ms=duration_ms,
        )

        self._print_summary(pipeline_result)
        return pipeline_result

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _step_cwd(self, step: Step) -> Path:
        if step.cwd:
            return self.project_root / step.cwd
        return self.project_root

    def _run_step(self, step: Step, *, dry_run: bool = False) -> StepResult:
        cmd_str = " ".join(step.command)
        cwd = self._step_cwd(step)
        cwd_display = cwd.relative_to(self.project_root) if cwd != self.project_root else Path(".")

        console.print(f"\n  [bold blue]▶[/bold blue] {step.name}")
        console.print(f"    [dim]$ {cmd_str}[/dim]  [dim](in {cwd_display})[/dim]")

        if dry_run:
            console.print("    [yellow]skipped (dry-run)[/yellow]")
            return StepResult(step=step, status=StepStatus.SKIPPED)

        env = {**os.environ, **step.env}
        start = time.monotonic()
        try:
            proc = subprocess.run(
                step.command,
                cwd=cwd,
                env=env,
                capture_output=False,  # stream output to terminal
                text=True,
            )
        except FileNotFoundError as exc:
            duration_ms = int((time.monotonic() - start) * 1000)
            console.print(f"    [red]✗ command not found: {exc}[/red]")
            return StepResult(
                step=step,
                status=StepStatus.FAILED,
                returncode=127,
                stderr=str(exc),
                duration_ms=duration_ms,
            )

        duration_ms = int((time.monotonic() - start) * 1000)
        status = StepStatus.SUCCESS if proc.returncode == 0 else StepStatus.FAILED
        icon = "[green]✓[/green]" if status == StepStatus.SUCCESS else "[red]✗[/red]"
        console.print(f"    {icon} exit {proc.returncode}  ({duration_ms} ms)")

        return StepResult(
            step=step,
            status=status,
            returncode=proc.returncode,
            duration_ms=duration_ms,
        )

    def _print_summary(self, result: PipelineResult) -> None:
        total = len(result.step_results)
        passed = sum(1 for r in result.step_results if r.status == StepStatus.SUCCESS)
        failed = sum(1 for r in result.step_results if r.status == StepStatus.FAILED)
        skipped = sum(1 for r in result.step_results if r.status == StepStatus.SKIPPED)

        status_color = "green" if result.status == StepStatus.SUCCESS else "red"
        status_label = "PASSED" if result.status == StepStatus.SUCCESS else "FAILED"

        summary = Text()
        summary.append(f"{status_label}", style=f"bold {status_color}")
        summary.append(f"  {passed}/{total} steps", style="white")
        if failed:
            summary.append(f"  {failed} failed", style="red")
        if skipped:
            summary.append(f"  {skipped} skipped", style="yellow")
        summary.append(f"  {result.duration_ms} ms", style="dim")

        title = f"[{status_color}]Pipeline: {result.pipeline}[/{status_color}]"
        console.print(Panel(summary, title=title, expand=False))
