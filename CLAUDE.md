# CLAUDE.md — Project Context

## What This Is

Reverse-engineered analysis of `@anthropic-ai/claude-code` v2.1.88. The original TypeScript source (1,902 files) was recovered losslessly from the bundled source map.

## Key References

- **[AGENTS.md](./AGENTS.md)** — Full architecture guide, repository structure, agent guidance
- **[spec/architecture.md](./spec/architecture.md)** — System architecture and module organization
- **[spec/tools.md](./spec/tools.md)** — Tool system specification (inputs, outputs, registry)
- **[spec/commands.md](./spec/commands.md)** — Command system specification
- **[spec/state-management.md](./spec/state-management.md)** — State management patterns
- **[spec/decompilation.md](./spec/decompilation.md)** — Decompilation methodology and results

## Quick Start

```bash
# View recovered source
ls decompiled/src/

# Run tests
npx vitest run

# Extract source from source map (already done)
node -e "const m=JSON.parse(require('fs').readFileSync('cli.js.map','utf8')); ..."
```

## Project Layout

- `src/` — 1,902 recovered TypeScript source files (read-only reference)
- `data/package/sdk-tools.d.ts` — Public SDK type definitions (20 input + 20 output types)
- `data/package/cli.js` — Bundled CLI (13MB minified JS)
- `data/package/cli.js.map` — Source Map v3 (60MB, 4,756 embedded sources)
- `data/package/vendor/` — Pre-built native binaries (ripgrep, audio-capture)
- `spec/` — Specification documents
- `tests/` — Unit tests

## Conventions

- Source files use TypeScript with React/JSX (`.ts`, `.tsx`)
- Terminal UI uses Ink (React for terminals) with Yoga layout
- State management uses a Zustand-like single store pattern
- Tools use Zod for input validation
- Commands use a discriminated union pattern (Prompt/Local/LocalJSX)
- ESM modules (`"type": "module"`)
- Node.js >= 18 required
