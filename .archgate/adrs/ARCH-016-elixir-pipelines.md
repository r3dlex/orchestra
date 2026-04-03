# ARCH-016: Mix Tasks for All Pipelines

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
The CI pipeline needs to be reproducible locally. External CI tools (Make, shell scripts, Taskfile) add complexity.

## Decision
All pipeline steps are Mix tasks. `mix pipeline` runs the full CI sequence. `mix test.artifacts` generates proof artifacts. npx archgate is the only non-Mix external tool.

## Consequences
`mix pipeline` works identically locally and in CI. No Makefile, no shell scripts, no external task runners.
