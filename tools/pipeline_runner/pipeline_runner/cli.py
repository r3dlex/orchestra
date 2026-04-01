"""Click CLI entry point for the pipeline runner."""

from __future__ import annotations

import sys

import click
from rich.console import Console
from rich.table import Table

from .models import StepStatus
from .pipelines import PIPELINES
from .runner import PipelineRunner

console = Console()


@click.group()
@click.version_option(package_name="pipeline-runner")
def main() -> None:
    """Pipeline runner for the claude-code project.

    Runs ordered sequences of steps (Node.js tests, archgate ADR checks,
    Python linting, etc.) from the project root.
    """


@main.command("run")
@click.argument("name", metavar="PIPELINE")
@click.option(
    "--dry-run",
    is_flag=True,
    default=False,
    help="Print each step's command without executing it.",
)
@click.option(
    "--cwd",
    default=None,
    metavar="DIR",
    help="Override the project root directory.",
)
def run_pipeline(name: str, dry_run: bool, cwd: str | None) -> None:
    """Run the named PIPELINE.

    Available pipelines can be listed with the `list` command.
    """
    if name not in PIPELINES:
        available = ", ".join(PIPELINES)
        console.print(f"[red]Error:[/red] unknown pipeline '{name}'. Available: {available}")
        sys.exit(1)

    runner = PipelineRunner(cwd=cwd)
    result = runner.run(name, dry_run=dry_run)
    sys.exit(0 if result.status in (StepStatus.SUCCESS, StepStatus.SKIPPED) else 1)


@main.command("list")
def list_pipelines() -> None:
    """List all available pipelines."""
    table = Table(title="Available pipelines", show_header=True, header_style="bold cyan")
    table.add_column("Name", style="bold")
    table.add_column("Description")
    table.add_column("Steps", justify="right")

    for pipeline in PIPELINES.values():
        table.add_row(pipeline.name, pipeline.description, str(len(pipeline.steps)))

    console.print(table)


@main.command("inspect")
@click.argument("name", metavar="PIPELINE")
def inspect_pipeline(name: str) -> None:
    """Show the steps of a pipeline without running it."""
    if name not in PIPELINES:
        available = ", ".join(PIPELINES)
        console.print(f"[red]Error:[/red] unknown pipeline '{name}'. Available: {available}")
        sys.exit(1)

    pipeline = PIPELINES[name]
    console.print(f"\n[bold cyan]{pipeline.name}[/bold cyan]  {pipeline.description}\n")

    for i, step in enumerate(pipeline.steps, 1):
        cmd = " ".join(step.command)
        cwd_note = f"  [dim](in {step.cwd})[/dim]" if step.cwd else ""
        console.print(f"  {i}. [bold]{step.name}[/bold]")
        console.print(f"     [dim]$ {cmd}[/dim]{cwd_note}")
