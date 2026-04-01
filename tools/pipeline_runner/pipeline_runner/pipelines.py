"""Built-in pipeline definitions for the claude-code project."""

from __future__ import annotations

from .models import Pipeline, Step

# ---------------------------------------------------------------------------
# Individual step definitions (reused across pipelines)
# ---------------------------------------------------------------------------

_install_node_deps = Step(
    name="Install Node.js dependencies",
    command=["npm", "ci"],
)

_run_tests = Step(
    name="Run tests with coverage",
    command=["npx", "vitest", "run", "--coverage"],
)

_archgate_check = Step(
    name="Archgate ADR compliance check",
    command=["npx", "--yes", "archgate@latest", "check"],
)

_python_tests = Step(
    name="Run Python pipeline-runner tests",
    command=["poetry", "run", "pytest", "--tb=short"],
    cwd="tools/pipeline_runner",
)

_python_lint = Step(
    name="Lint pipeline-runner (ruff)",
    command=["poetry", "run", "ruff", "check", "."],
    cwd="tools/pipeline_runner",
)

_python_typecheck = Step(
    name="Type-check pipeline-runner (mypy)",
    command=["poetry", "run", "mypy", "pipeline_runner"],
    cwd="tools/pipeline_runner",
)

# ---------------------------------------------------------------------------
# Pipeline registry
# ---------------------------------------------------------------------------

PIPELINES: dict[str, Pipeline] = {
    "test": Pipeline(
        name="test",
        description="Run the full Node.js test suite with coverage.",
        steps=[_install_node_deps, _run_tests],
    ),
    "archgate": Pipeline(
        name="archgate",
        description="Run archgate ADR compliance check.",
        steps=[_archgate_check],
    ),
    "python-test": Pipeline(
        name="python-test",
        description="Run Python pipeline-runner unit tests.",
        steps=[_python_tests],
    ),
    "python-lint": Pipeline(
        name="python-lint",
        description="Lint and type-check the Python pipeline-runner.",
        steps=[_python_lint, _python_typecheck],
    ),
    "ci": Pipeline(
        name="ci",
        description="Full CI pipeline: Node tests + ADR check + Python tests.",
        steps=[
            _install_node_deps,
            _run_tests,
            _archgate_check,
            _python_tests,
        ],
    ),
}
