# ARCH-015: Burrito for Zero-Install Binary Distribution

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Elixir releases require the target to have Erlang installed. Most users don't have Erlang. Burrito wraps the release + ERTS into a self-contained binary using Zig.

## Decision
Burrito from day one. Release targets: linux x86_64, macOS x86_64, macOS arm64. Build on every release tag via CI. Zig 0.13.0 is a dev dependency.

## Consequences
50-100MB binary, no runtime dependencies. Zig must be in the build environment. escript offered as alternative for existing Erlang users.
