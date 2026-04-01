"""Shared fixtures for pipeline-runner tests."""

from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture
def project_root() -> Path:
    """Return the actual project root (parent of tools/)."""
    return Path(__file__).resolve().parents[3]
