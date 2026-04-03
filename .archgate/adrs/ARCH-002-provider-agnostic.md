# ARCH-002: Provider-Agnostic Design via Behaviour + Presets

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
Musician must support multiple LLM providers (MiniMax, Claude, Codex, Gemini, Ollama, custom). Hardcoding any provider would create lock-in and require code changes to add new providers.

## Decision
Define MusicianCore.Provider.Behaviour with callbacks: name/0, complete/2, stream/2, list_models/1, supports_tools?/0. Provider implementations are modules that implement this behaviour. Presets are convenience configs, not hardcoded logic.

## Consequences
Any OpenAI-compatible endpoint works with zero code changes. Claude requires its own module for Anthropic Messages API translation. Adding a new provider = implementing one behaviour + adding a preset.
