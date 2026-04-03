---
id: GEN-001
title: TDD with Real Source Imports
domain: general
rules: true
files: ["tests/src-*.test.ts", "tests/src-*-*.test.ts"]
---

## Context

This project is a reverse-engineered analysis of `@anthropic-ai/claude-code` v2.1.88, with
1,902 TypeScript source files recovered losslessly from the bundled source map in `src/`.

Early tests re-implemented logic inline (copying function bodies into the test file). This
gave 0% measured coverage because coverage tools only track code that is actually imported and
executed — not code re-typed in a test file.

**Alternatives considered:**

- **Inline re-implementations** — Copy the function under test directly into the test file.
  Simple to write but produces zero measured coverage. Test failures cannot distinguish between
  "the implementation is broken" and "my copy is wrong". Drift between copy and source is
  invisible.

- **Snapshot testing against the bundle** — Run the minified `cli.js` and snapshot output.
  Tests the end-to-end behaviour but cannot produce fine-grained unit coverage and is brittle
  to minification changes.

- **Real imports (chosen)** — Import directly from `src/utils/*.ts` using the `.js` extension
  (Vitest resolves `.js` → `.ts` transparently for ESM). Produces real measured coverage.
  Failures unambiguously indicate a broken source function. Easy to read alongside the source.

## Decision

All test files in `tests/` MUST import the functions under test from the real `src/` modules.
No test file may re-implement a function inline when a real import is available.

**Key constraints:**

1. **Use `.js` extension** — `import { fn } from '../src/utils/foo.js'` (ESM + Vitest convention).
2. **Mock only unavailable deps** — modules that use `bun:bundle` (e.g. `slowOperations.ts`,
   `log.ts`) must be stubbed via `vi.mock()` so Vitest can import them in Node.js.
3. **No inline re-implementations** — do not copy function bodies into test files.
4. **Coverage target** — maintain ≥ 90% lines/statements/functions and ≥ 80% branches on the
   files listed in `vitest.config.ts` coverage `include`.

## Do's and Don'ts

### Do

- `import { myFn } from '../src/utils/myModule.js'` — real import
- `vi.mock('../src/utils/slowOperations.js', () => ({ ... }))` — stub unavailable Bun dep
- Use `await import(...)` at the module top level (ESM dynamic import is valid in Vitest)
- Use `vi.resetModules()` + `globalThis.Bun = ...` before import for Bun-path coverage

### Don't

- Don't copy function implementations into test files
- Don't skip `vi.mock` for modules that transitively depend on `bun:bundle`
- Don't use `require()` — this is an ESM project

## Consequences

### Positive

- Measured coverage; failures point to real bugs; tests stay in sync with source automatically

### Negative

- More setup for modules with heavy transitive deps (need `vi.mock` boilerplate)

### Risks

- None — Vitest handles `.js` → `.ts` resolution transparently

## Compliance and Enforcement

Rule `GEN-001/real-src-imports`: Verifies each test file imports from `../src/`. Severity: error.

## References

- [Vitest coverage docs](https://vitest.dev/guide/coverage)
- [src/utils/](../../src/utils/) — source modules under test
