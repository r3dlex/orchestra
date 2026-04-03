# ARCH-012: JSONL for Session History

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Session history needs to be appendable, human-readable, and searchable. Structured binary formats complicate debugging. SQLite is overkill for append-only logs.

## Decision
JSONL (newline-delimited JSON) at ~/.musician/history.jsonl. Each line is one session summary. Search via keyword grep, time range filter, or LLM summarization.

## Consequences
Simple append. Easy to inspect with jq. Max 500 entries configurable. Older entries rotated out.
