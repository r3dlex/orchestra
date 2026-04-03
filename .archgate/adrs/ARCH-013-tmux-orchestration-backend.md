# ARCH-013: tmux as Sole Orchestration Backend

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Orchestra needs to run multiple AI agents concurrently, each in its own terminal session with visible output. Options considered: tmux, screen, raw PTYs, background processes.

## Decision
tmux is the sole orchestration backend. Each worker gets a tmux pane. Output is captured via capture-pane. Requires tmux >= 3.0. WSL2 required on Windows.

## Consequences
Visible worker output (great for debugging). tmux must be installed. Orchestra unavailable without tmux (Musician core still works).
