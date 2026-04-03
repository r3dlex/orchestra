# ARCH-001: Elixir Umbrella Project Structure

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
The project has 10 distinct application concerns (core, auth, tools, skills, memory, session, tui, cli, plugins, orchestra). These need clear boundaries and independent testability while sharing deps and build artifacts.

## Decision
Use an Elixir umbrella project at the repo root. All apps live in apps/. Shared deps compiled once in _build/ at the root. Each app has its own mix.exs with in_umbrella: true.

## Consequences
Clear separation of concerns. Independent test runs per app. mix compile at root compiles all. Burrito release builds from musician_cli app.
