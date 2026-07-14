import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";

describe("self-hosted CI fallback", () => {
  it("makes every self-hosted job opt-in", () => {
    const workflow = readFileSync(resolve(".github/workflows/ci.yml"), "utf8");
    const jobs = [
      ...workflow.matchAll(
        /^  (_[^:\n]+-self-hosted):\n([\s\S]*?)(?=^  [A-Za-z0-9_-]+:\n|(?![\s\S]))/gm,
      ),
    ];

    expect(jobs.length).toBeGreaterThan(0);
    for (const [, name, body] of jobs) {
      expect(body, name).toMatch(/^[ ]{4}if: .*vars\.SELF_HOSTED_CI_ENABLED/m);
    }
  });
});
