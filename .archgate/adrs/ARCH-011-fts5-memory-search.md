# ARCH-011: SQLite FTS5 for Memory Search

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Memory retrieval needs full-text search over body and tags fields. External search services are too heavy for a local CLI tool.

## Decision
SQLite with the FTS5 extension for memory search. exqlite Hex package. Content-table approach: FTS5 virtual table mirrors the memories table with triggers for sync.

## Consequences
Fast full-text search with no external service. FTS5 available in SQLite >= 3.9 (standard on all target platforms). exqlite compiles the SQLite amalgamation with FTS5 enabled.
