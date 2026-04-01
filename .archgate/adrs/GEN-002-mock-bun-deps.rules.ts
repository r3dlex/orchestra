/// <reference path="../rules.d.ts" />

/** Modules that transitively require bun-only deps and therefore need vi.mock stubs. */
const BUN_DEPENDENT_IMPORTS = ["memoize.js", "json.js"] as const;

export default {
  rules: {
    "mock-slowoperations": {
      description:
        "Test files importing memoize.js or json.js must vi.mock slowOperations.js",
      severity: "error",
      async check(ctx) {
        for (const file of ctx.scopedFiles) {
          const content = await ctx.readFile(file);

          const importsBunDep = BUN_DEPENDENT_IMPORTS.some((m) => content.includes(m));
          if (!importsBunDep) continue;

          if (!content.includes("slowOperations")) {
            ctx.report.violation({
              message:
                "This test imports a bun-dependent module (memoize.js / json.js) " +
                "but does not mock `slowOperations.js`. " +
                "Add `vi.mock('../src/utils/slowOperations.js', () => ({ ... }))` " +
                "before any src/ import.",
              file,
              fix: "Add vi.mock('../src/utils/slowOperations.js', () => ({ jsonStringify: JSON.stringify, ... }))",
            });
          }
        }
      },
    },

    "mock-log": {
      description:
        "Test files importing memoize.js or json.js must vi.mock log.js",
      severity: "error",
      async check(ctx) {
        for (const file of ctx.scopedFiles) {
          const content = await ctx.readFile(file);

          const importsBunDep = BUN_DEPENDENT_IMPORTS.some((m) => content.includes(m));
          if (!importsBunDep) continue;

          const hasMock =
            content.includes("vi.mock('../src/utils/log.js'") ||
            content.includes('vi.mock("../src/utils/log.js"');
          if (!hasMock) {
            ctx.report.violation({
              message:
                "This test imports a bun-dependent module (memoize.js / json.js) " +
                "but does not mock `log.js`. " +
                "Add `vi.mock('../src/utils/log.js', () => ({ logError: vi.fn(), ... }))` " +
                "before any src/ import.",
              file,
              fix: "Add vi.mock('../src/utils/log.js', () => ({ logError: vi.fn(), logForDebugging: vi.fn() }))",
            });
          }
        }
      },
    },
  },
} satisfies RuleSet;
