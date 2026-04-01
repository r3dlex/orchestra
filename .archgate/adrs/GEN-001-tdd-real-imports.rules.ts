/// <reference path="../rules.d.ts" />

export default {
  rules: {
    "real-src-imports": {
      description:
        "Test files must import from real src/ modules, not re-implement logic inline",
      severity: "error",
      async check(ctx) {
        // No exemptions needed — file glob already scopes to src-*.test.ts files.
        const exempt = new Set<string>();

        for (const file of ctx.scopedFiles) {
          const normalised = file.replaceAll("\\", "/");
          if ([...exempt].some((p) => normalised.endsWith(p))) continue;

          const content = await ctx.readFile(file);

          // A test file satisfies this rule if it has at least one import from '../src/'
          const hasSrcImport =
            /from\s+['"]\.\.\/src\//.test(content) ||
            /import\s*\(.*['"]\.\.\/src\//.test(content);

          if (!hasSrcImport) {
            ctx.report.violation({
              message:
                "Test file has no imports from '../src/'. " +
                "Use real source imports (e.g. `import { fn } from '../src/utils/foo.js'`) " +
                "to produce measured coverage.",
              file,
              fix: "Replace inline re-implementations with `import { ... } from '../src/utils/<module>.js'`",
            });
          }
        }
      },
    },
  },
} satisfies RuleSet;
