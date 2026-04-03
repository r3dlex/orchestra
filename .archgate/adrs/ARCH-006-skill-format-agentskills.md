# ARCH-006: SKILL.md Format with agentskills.io Compatibility

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Skills need to be portable across AI agent tools (Claude Code, oh-my-claudecode, future tools). Each agent tool may have additional metadata needs.

## Decision
SKILL.md with YAML frontmatter is the canonical skill format, compatible with agentskills.io. Musician-specific metadata (improvement history, invocation stats, quality gate results) lives in a sidecar .musician.yaml file alongside SKILL.md.

## Consequences
Skills are portable — SKILL.md works anywhere. Musician enhancement data is isolated in the sidecar and doesn't pollute the portable format.
