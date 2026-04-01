# pipeline-runner

Pipeline runner for the [claude-code](../../README.md) reverse-engineering project.

## Installation

Requires Python ≥ 3.12. Uses [Poetry](https://python-poetry.org/) for dependency management.
Python itself is installed zero-touch via [mise](https://mise.jdx.dev/) — run `mise install`
from the project root.

```bash
# From project root (mise manages Python):
mise install
pip install poetry
cd tools/pipeline_runner && poetry install
```

## Usage

```bash
# List available pipelines
poetry run pipeline list

# Run the full CI pipeline
poetry run pipeline run ci

# Run only Node.js tests
poetry run pipeline run test

# Run archgate ADR check
poetry run pipeline run archgate

# Dry-run (print steps, don't execute)
poetry run pipeline run ci --dry-run

# Inspect a pipeline's steps
poetry run pipeline inspect ci
```

## Pipelines

| Name          | Description                                     |
|---------------|-------------------------------------------------|
| `test`        | Node.js tests with coverage (vitest)            |
| `archgate`    | ADR compliance check (archgate)                 |
| `python-test` | Python pipeline-runner unit tests               |
| `python-lint` | Ruff lint + mypy type-check                     |
| `ci`          | Full CI: Node tests + ADR check + Python tests  |

## Development

```bash
cd tools/pipeline_runner
make check     # lint + typecheck + test
make test      # pytest only
make lint      # ruff only
make typecheck # mypy only
```
