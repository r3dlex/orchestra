# claude-code — Reverse Engineered Source

Lossless TypeScript source recovery of `@anthropic-ai/claude-code` v2.1.88 — Anthropic's agentic CLI coding tool — extracted from the embedded source map.

## What Is This?

The published npm package ships a 13MB bundled `cli.js` alongside a 60MB source map containing **4,756 fully embedded source files**. This repo extracts and documents the original 1,902 TypeScript source files, with a test suite to verify the artifacts.

## Repository Structure

```
.
├── src/                        # 1,902 recovered TypeScript source files
│   ├── entrypoints/            # CLI bootstrap (cli.tsx, mcp.ts, sdk/)
│   ├── main.tsx                # Core initialization (~4,600 lines)
│   ├── tools.ts / tools/       # Tool registry + 184 tool implementations
│   ├── commands.ts / commands/ # Command registry + 207 slash commands
│   ├── components/             # 389 React/Ink terminal UI components
│   ├── hooks/                  # 104 React hooks
│   ├── services/               # 130 service modules (MCP, API, analytics)
│   ├── utils/                  # 564 utility modules
│   ├── state/                  # Global app state store
│   ├── ink/                    # Custom Ink terminal renderer (96 files)
│   ├── types/                  # Core TypeScript type definitions
│   └── ...                     # 25+ more directories
│
├── data/package/               # Original npm package artifacts
│   ├── cli.js                  # Bundled CLI (13MB, 16,667 lines, minified)
│   ├── cli.js.map              # Source Map v3 (60MB, 4,756 embedded sources)
│   ├── sdk-tools.d.ts          # Public SDK type definitions (117KB)
│   ├── bun.lock                # Bun lockfile
│   ├── LICENSE.md              # Original package license
│   └── vendor/                 # Pre-built native binaries
│       ├── ripgrep/            # rg binaries: arm64/x64 × darwin/linux/win32
│       └── audio-capture/      # .node binaries: arm64/x64 × darwin/linux/win32
│
├── spec/                       # Architecture documentation
│   ├── architecture.md         # System overview and module map
│   ├── tools.md                # Tool system (inputs, outputs, registry)
│   ├── commands.md             # Command system specification
│   ├── state-management.md     # State management patterns
│   └── decompilation.md        # Recovery methodology
│
├── tests/                      # Test suite (248 tests)
│   ├── source-map-extraction.test.ts  # Source map integrity
│   ├── bundle-analysis.test.ts        # Bundle + vendor verification
│   ├── sdk-types.test.ts              # SDK type definitions coverage
│   ├── decompiled-utils.test.ts       # Array, XML, UUID, format, JSON utils
│   ├── decompiled-words.test.ts       # Word slug generators
│   ├── decompiled-paths.test.ts       # Path conversion + arg substitution
│   └── decompiled-keywords.test.ts    # Keyword matching + timestamps
│
├── AGENTS.md                   # Architecture guide for AI agents
├── CLAUDE.md                   # Project context for Claude Code
├── package.json                # Repo manifest with test scripts
└── vitest.config.ts            # Test configuration
```

## Recovery Method

The source map (`data/package/cli.js.map`) is a standard [Source Map v3](https://tc39.es/source-map/) file with `sourcesContent` populated — meaning each original source file's full content is embedded verbatim. Recovery is lossless:

```js
const map = JSON.parse(fs.readFileSync('data/package/cli.js.map', 'utf8'))
// map.sources[i]        → relative path like "../src/utils/array.ts"
// map.sourcesContent[i] → complete original file content
```

No heuristic decompilation was needed. The recovered TypeScript is identical to the original source as written by Anthropic engineers.

## Source Statistics

| Category | Count |
|----------|-------|
| Total source map entries | 4,756 |
| Application `.ts` / `.tsx` files | 1,902 |
| Of which `.ts` | 1,332 |
| Of which `.tsx` | 552 |
| `node_modules` entries | 2,850 |

## Architecture Highlights

**Entry chain**: `cli.tsx` → `main.tsx` → `REPL.tsx` → `query.ts`

**Tools** (20 public types in `sdk-tools.d.ts`):
Bash, Read, Edit, Write, Glob, Grep, Agent, WebFetch, WebSearch, TodoWrite, AskUserQuestion, NotebookEdit, EnterWorktree, ExitWorktree, ExitPlanMode, Config, TaskOutput, TaskStop, ListMcpResources, ReadMcpResource

**UI**: Custom [Ink](https://github.com/vadimdemedes/ink) implementation (React for terminals) with Yoga layout engine — 96 files in `src/ink/`

**State**: Zustand-like single store (`src/state/`) with `DeepImmutable<T>` snapshots and speculation (parallel pre-generation)

**Permissions**: Mode-based (default / auto / bypass / plan) + rule-based (allow / deny / ask) system

See [spec/architecture.md](spec/architecture.md) and [AGENTS.md](AGENTS.md) for full details.

## Running Tests

```sh
npm install
npm test
```

Expected output:
```
Tests  248 passed (248)
Test Files  7 passed (7)
```

## Notes

- The recovered `src/` is **read-only reference material** — it cannot be rebuilt without the full Anthropic build system and private dependencies
- Some files reference internal infrastructure (telemetry, feature flags via GrowthBook) that is not publicly accessible
- Built with Bun's bundler; build time `2026-03-30T21:59:52Z`
- Node.js ≥ 18 required (ESM)
