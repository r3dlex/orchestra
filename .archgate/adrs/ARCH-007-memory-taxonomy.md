# ARCH-007: Four Memory Types: user, feedback, project, reference

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Persistent memory needs a taxonomy to make retrieval useful and avoid storing irrelevant data. Same taxonomy as Claude Code's memory system for conceptual consistency.

## Decision
Four types — user (who the user is), feedback (how to collaborate), project (ongoing work context), reference (where to find things). Two scopes — private and team. SQLite with FTS5 for search.

## Consequences
Structured retrieval. Memory decay logic per type (project memories expire at 90 days, reference memories persist).
