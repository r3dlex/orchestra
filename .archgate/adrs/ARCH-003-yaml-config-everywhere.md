# ARCH-003: YAML for All Configuration

**Status:** Accepted
**Date:** 2026-04-03
**Deciders:** Andre Burgstahler

## Context
The project needs a human-readable config format. JSON lacks comments. TOML has mixed ecosystem support in Elixir. YAML is widely understood and yaml_elixir is a mature Hex package.

## Decision
All configuration files use YAML. Global config at ~/.musician/config.yaml. Local override at .musician/config.yaml. Auth tokens at ~/.musician/auth/. Parse with yaml_elixir. No JSON config, no TOML config.

## Consequences
Consistent config format. yaml_elixir dep required. YAML indentation sensitivity is a minor DX risk mitigated by schema validation.
