# ARCH-010: Gemini OAuth Deferred to v1.1

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Gemini supports both API key (simple) and OAuth 2.0 Authorization Code + PKCE (for Google Workspace SSO users). OAuth setup requires Google Cloud Console configuration.

## Decision
v1 uses Gemini API key only (GEMINI_API_KEY). OAuth Auth Code + PKCE implementation is fully documented in spec/010-gemini-oauth-v11.md and scheduled for v1.1.

## Consequences
v1 Gemini users need a Google AI Studio API key. v1.1 adds full OAuth flow documented in spec/010.
