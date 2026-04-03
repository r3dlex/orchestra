# Decompilation & Transpilation Report

## Source Recovery Method

### Input Artifacts
| File | Size | Content |
|------|------|---------|
| `data/package/cli.js` | 13MB (16,667 lines) | Bundled, minified JavaScript |
| `data/package/cli.js.map` | 60MB | Source Map v3 with embedded sources |
| `data/package/sdk-tools.d.ts` | 117KB (2,719 lines) | TypeScript type definitions |

### Recovery Process

The source map (`cli.js.map`) contains **full original source content** via the `sourcesContent` field. This is a complete, lossless recovery — not a heuristic decompilation.

```
Source Map v3 Structure:
  version: 3
  sources: 4,756 file paths
  sourcesContent: 4,756 complete file contents
  mappings: line/column position mappings
```

### Extracted Files

| Category | Count | Extensions |
|----------|-------|------------|
| Application source | 1,902 | .ts (1,332), .tsx (552), .js (18) |
| node_modules | 2,850 | various |
| Other | 4 | various |
| **Total** | **4,756** | |

### Output
All 1,902 application source files extracted to `src/` preserving original directory structure.

## What Was Recovered

### Complete TypeScript Source
- Full type annotations preserved
- JSX/TSX markup intact
- Import/export statements original
- Comments and documentation preserved
- All 1,902 files with original formatting

### What Is NOT Recoverable from cli.js Alone
- Without the source map, the bundled `cli.js` has:
  - Mangled variable names (e.g., `q`, `K`, `_`, `z`)
  - Flattened module structure (everything in one file)
  - Removed type annotations (JS has no types)
  - Removed import/export boundaries
  - Tree-shaken dead code eliminated

### Source Map Mapping Quality
The source map provides bidirectional mapping between:
- Original `.ts`/`.tsx` source positions
- Bundled `cli.js` positions

This enables:
- Accurate stack traces pointing to original source
- Debugger breakpoints on original TypeScript
- Full source-level debugging

## Type Definitions (data/package/sdk-tools.d.ts)

The `data/package/sdk-tools.d.ts` file provides the **public SDK API surface**:
- Auto-generated from JSON Schema (`json-schema-to-typescript`)
- 20 tool input types + 20 tool output types
- Complete type information for all tool parameters
- Discriminated unions for polymorphic outputs (FileRead, Agent, etc.)

## Build System

- **Bundler**: Bun (inferred from `bun.lock`)
- **Build time**: 2026-03-30T21:59:52Z
- **Output**: Single ESM bundle with source map
- **Target**: Node.js >= 18
