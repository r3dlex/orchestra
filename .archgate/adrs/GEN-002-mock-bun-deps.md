---
id: GEN-002
title: Mock Bun-Only Transitive Dependencies in Tests
domain: general
rules: true
files: ["tests/src-*.test.ts", "tests/src-*-*.test.ts"]
---

## Context

Several `src/utils/` modules (`memoize.ts`, `json.ts`) transitively depend on modules that use
`import { feature } from 'bun:bundle'` — a Bun-only internal module unavailable in the Node.js
runtime that Vitest uses. Without mocking these transitive dependencies, importing `memoize.ts`
or `json.ts` throws a module-not-found error at test time.

**Affected modules that must be mocked:**
- `src/utils/slowOperations.ts` — uses `bun:bundle`, exports `jsonStringify`, `jsonParse`,
  `clone`, `cloneDeep`, `slowLogging`, `SLOW_OPERATION_THRESHOLD_MS`, `callerFrame`.
- `src/utils/log.ts` — uses `bun:bundle`, exports `logError`, `logForDebugging`.

**Alternatives considered:**

- **Skip tests for these modules** — Would leave `memoize.ts` and `json.ts` without coverage. Not acceptable.
- **Run tests in Bun** — Would require all developers and CI to use Bun. Not acceptable.
- **Patch modules with conditional imports** — Modifying source files defeats the read-only reference purpose.
- **`vi.mock()` stubs (chosen)** — Provide pure-JS equivalents using Vitest's mock hoisting. Zero overhead.

## Decision

Any test file that imports a module which transitively requires `slowOperations.ts` or `log.ts`
MUST declare `vi.mock()` stubs for both modules before any `import` from `src/`.

**Required stub for `slowOperations.ts`:**

```typescript
vi.mock('../src/utils/slowOperations.js', () => ({
  jsonStringify: JSON.stringify,
  jsonParse: JSON.parse,
  clone: structuredClone,
  cloneDeep: (v: unknown) => JSON.parse(JSON.stringify(v)),
  slowLogging: () => ({ [Symbol.dispose]() {} }),
  SLOW_OPERATION_THRESHOLD_MS: Infinity,
  callerFrame: () => '',
}))
```

**Required stub for `log.ts`:**

```typescript
vi.mock('../src/utils/log.js', () => ({
  logError: vi.fn(),
  logForDebugging: vi.fn(),
}))
```

## Do's and Don'ts

### Do

- Declare `vi.mock(...)` before `await import(...)` for bun-dependent modules
- Keep the `slowOperations` stub semantically equivalent (real JSON/clone operations)
- Use `vi.fn()` for log helpers so you can assert they were called

### Don't

- Don't import `memoize.js` or `json.js` without the required mocks
- Don't throw in mock factories — all exports must be non-throwing stubs
- Don't remove the `[Symbol.dispose]` from the `slowLogging` stub

## Consequences

### Positive

- `memoize.ts` and `json.ts` fully tested with real measured coverage in Node.js/Vitest

### Negative

- Mock boilerplate duplicated in every test file that needs it (vi.mock() is per-file)

### Risks

- If `slowOperations.ts` exports change, mocks must be updated manually

## Compliance and Enforcement

- Rule `GEN-002/mock-slowoperations`: Tests importing `memoize.js`/`json.js` must mock `slowOperations.js`. Severity: error.
- Rule `GEN-002/mock-log`: Tests importing `memoize.js`/`json.js` must mock `log.js`. Severity: error.

## References

- `src/utils/slowOperations.ts` — Bun-only operations
- `src/utils/log.ts` — Bun-only logging
