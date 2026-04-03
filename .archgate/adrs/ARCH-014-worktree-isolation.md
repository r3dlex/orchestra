# ARCH-014: Git Worktree Isolation Per Worker

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Multiple Orchestra workers modifying the same codebase simultaneously creates merge conflicts. Workers need isolated filesystems.

## Decision
Each Orchestra worker gets a dedicated git worktree on a feature branch. Workers commit to their branch. Orchestra merges results incrementally. Worktrees are cleaned up after merge.

## Consequences
Zero conflicts between workers. Merge step requires conflict resolution logic. Worktree overhead is disk space (full repo copy per worker).
