# ARCH-009: Device Code Flow for Codex Authentication

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Codex (OpenAI) does not support simple API key auth for CLI use. They recommend the OAuth 2.0 Device Code flow with their public client ID.

## Decision
Implement Device Code flow for Codex in musician_auth. The public client ID is app_EMoamEEZ73f0CkXaXp7hrann. Tokens stored in ~/.musician/auth/codex.yaml with refresh logic.

## Consequences
Users authenticate Codex via browser (one-time). Tokens refresh automatically. Implementation lives in MusicianAuth.CodexDevice.
