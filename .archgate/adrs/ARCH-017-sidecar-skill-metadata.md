# ARCH-017: Sidecar .musician.yaml for Skill Improvement Metadata

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
SKILL.md must stay portable (agentskills.io compatible). Musician-specific improvement metadata (invocation count, success rate, improvement history) cannot pollute SKILL.md.

## Decision
Each skill directory contains SKILL.md (portable) + .musician.yaml (sidecar). The sidecar tracks: created_at, improved_count, total_invocations, success_rate, status, improvements list, quality_gate results.

## Consequences
Portable skills for other tools. Rich metadata for Musician's self-improvement loop. Sidecar ignored by non-Musician tools.
