# ARCH-018: Backend Registry for Orchestra Workers

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Orchestra workers can be native CLI binaries (claude, codex, gemini) or Musician instances with different provider configs. Available backends vary by user environment.

## Decision
Orchestra.Backends.Registry detects available backends at startup using System.find_executable/1. Workers are dispatched based on detected backends and user config. If no backends detected, Orchestra returns {:error, :no_backends}.

## Consequences
Graceful degradation when some CLIs are missing. User can always use musician as a backend (it's always available if musician itself is running).
