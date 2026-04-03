# ARCH-004: Auth Centralized at ~/.musician/

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Multiple providers need auth. Scattering auth files across the filesystem creates confusion and security risks.

## Decision
All auth state lives in ~/.musician/auth/. api_keys.yaml for API key providers. codex.yaml for Device Code tokens. Future OAuth tokens follow the same pattern. The musician_auth app owns all auth logic.

## Consequences
Single place to inspect and revoke auth. Clear ownership. chmod 600 on auth files recommended in setup wizard.
