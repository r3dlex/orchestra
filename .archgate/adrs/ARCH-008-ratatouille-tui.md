# ARCH-008: Ratatouille for Terminal UI

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
The TUI needs a structured, maintainable architecture. Raw termbox bindings are too low-level. Ratatouille provides an Elm-architecture (init/update/render) over termbox-ex.

## Decision
Use ratatouille (~> 0.5) for the TUI. Implement MusicianTui.App using Ratatouille.App behaviour. If ratatouille maintenance stalls, the fallback is forking it (~3K lines) or evaluating TermUI.

## Consequences
Clean separation of state and rendering. update/2 is pure and testable. render/1 is side-effectful and exempt from coverage targets.
