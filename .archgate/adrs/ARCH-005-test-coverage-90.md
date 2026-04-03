# ARCH-005: 90% Aggregate Test Coverage, TUI Exempt at 60%

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
LLM-adjacent code needs tests to catch bad model output and regressions. TUI render functions are hard to test without a real terminal.

## Decision
Aggregate coverage target >= 90%. Per-app targets: musician_core 95%, auth/tools/skills/memory/session 90%, musician_tui 60%, musician_plugins 85%, orchestra 80%. Coverage enforced in CI via mix test --cover.

## Consequences
High confidence in non-TUI code. TUI state transitions (update/2) are tested; render/1 is exempt.
