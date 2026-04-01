# AGENTS.md — Claude Code Reverse Engineering Guide

## Project Overview

This repository contains a decompiled analysis of the `@anthropic-ai/claude-code` npm package (v2.1.88), Anthropic's agentic CLI coding tool. The original TypeScript source was recovered losslessly from the embedded source map.

## Repository Structure

```
.
├── src/                   # 1,902 recovered TypeScript source files
│   ├── entrypoints/       # Bootstrap entry points (cli.tsx, mcp.ts, sdk/)
│   ├── main.tsx           # Core initialization (~4,600 lines)
│   ├── tools.ts           # Tool registry factory
│   ├── commands.ts        # Command registry (~200+ commands)
│   ├── query.ts           # API query loop
│   ├── tools/             # 184 tool implementations
│   ├── commands/          # 207 command implementations
│   ├── components/        # 389 React/Ink UI components
│   ├── hooks/             # 104 React hooks
│   ├── services/          # 130 service modules
│   ├── utils/             # 564 utility modules
│   ├── state/             # Global app state (Zustand-like)
│   ├── ink/               # Custom Ink terminal renderer
│   ├── bridge/            # Remote control system
│   ├── types/             # Core type definitions
│   └── ...                # 30+ more directories
├── data/
│   └── package/           # Original npm package artifacts
│       ├── cli.js          # Bundled CLI entry point (13MB, minified)
│       ├── cli.js.map      # Source Map v3 with 4,756 embedded sources
│       ├── sdk-tools.d.ts  # Public SDK type definitions (auto-generated)
│       ├── bun.lock        # Bun lockfile
│       ├── LICENSE.md      # Original package license
│       └── vendor/         # Pre-built native binaries (ripgrep, audio-capture)
├── spec/
│   ├── architecture.md    # System architecture overview
│   ├── tools.md           # Tool system specification
│   ├── commands.md        # Command system specification
│   ├── state-management.md # State management patterns
│   └── decompilation.md   # Decompilation methodology
├── tests/                 # Unit tests for visible/recoverable code
├── package.json           # Repo package manifest (with test scripts)
├── vitest.config.ts       # Test configuration
├── AGENTS.md              # This file
├── CLAUDE.md              # Project context for Claude Code
└── README.md              # Repository overview
```

## Architecture Summary

### Entry Point Chain
1. **cli.tsx** — Fast-path dispatch (version, bridge, MCP servers, worktree)
2. **main.tsx** — Full initialization (settings, auth, plugins, MCP, tools, commands)
3. **REPL.tsx** — Interactive terminal UI (Ink/React)
4. **query.ts** — Claude API loop (messages → tool calls → results → repeat)

### Core Abstractions

| Abstraction | Location | Count | Description |
|-------------|----------|-------|-------------|
| Tools | `tools/` | 184 files | Model-invocable actions (Bash, File ops, Web, Agent) |
| Commands | `commands/` | 207 files | User-invocable slash commands |
| Components | `components/` | 389 files | Terminal UI (React/Ink) |
| Hooks | `hooks/` | 104 files | React state/effect hooks |
| Services | `services/` | 130 files | Business logic (MCP, API, analytics) |
| Utils | `utils/` | 564 files | Shared utilities |

### Key Systems
- **Permission System** — Mode-based (default/auto/bypass/plan) + rule-based (allow/deny/ask)
- **MCP Integration** — StdIO transport to local MCP servers; tools, resources, commands
- **Plugin System** — Marketplace-based plugin installation and management
- **Skill System** — Builtin + bundled + plugin skills with forking support
- **State Store** — Centralized Zustand-like store with immutable snapshots
- **Speculation** — Parallel pre-generation of assistant responses

## Agent Guidance

### For Code Exploration
- Start with `src/entrypoints/cli.tsx` for the bootstrap flow
- Read `src/main.tsx` for the full initialization sequence
- Check `src/tools/` for individual tool implementations
- Check `src/commands/` for slash command implementations

### For Type Information
- `data/package/sdk-tools.d.ts` has the complete public API surface (20 input + 20 output types)
- `src/types/` has internal type definitions
- Tool inputs use Zod schemas; the `inputJSONSchema` property exposes JSON Schema

### For Testing
- Tests in `tests/` cover the public API types and recovered utility functions
- Run with: `npm test` or `npx vitest run`
- The source map extraction process itself is verified by file count assertions

### For Understanding Bundling
- Built with Bun bundler
- Single ESM output (`"type": "module"`)
- Source map has bidirectional position mappings
- Variable names are mangled in `data/package/cli.js` but original in source map

## Technical Notes

- The recovered source is **read-only reference** — it cannot be rebuilt into a working CLI without the full build system and dependencies
- The source map contains complete source content, making this a **lossless recovery** (not heuristic decompilation)
- Some files reference internal Anthropic infrastructure (telemetry, feature flags) that is not publicly accessible
- `data/package/vendor/` contains pre-built native binaries (ripgrep, audio-capture) for multiple platforms
