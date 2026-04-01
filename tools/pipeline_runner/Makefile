.PHONY: install test lint typecheck check all clean

install:
	poetry install --no-interaction

test:
	poetry run pytest --tb=short

lint:
	poetry run ruff check .

lint-fix:
	poetry run ruff check --fix .

typecheck:
	poetry run mypy pipeline_runner

check: lint typecheck test

run-%:
	poetry run pipeline run $*

list:
	poetry run pipeline list

clean:
	rm -rf .venv __pycache__ .pytest_cache .mypy_cache .ruff_cache htmlcov .coverage
