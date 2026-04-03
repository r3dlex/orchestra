import { defineRule } from "@archgate/core";

export default defineRule({
  name: "ARCH-001: umbrella-structure",
  description: "All application code must live in apps/ subdirectories. No lib/ at the umbrella root.",
  check({ files }) {
    const rootLibFiles = files.filter(
      (f) => f.path.startsWith("lib/") && !f.path.startsWith("lib/mix/")
    );
    return rootLibFiles.map((f) => ({
      file: f.path,
      message: `File ${f.path} must live inside an apps/ subdirectory, not at the umbrella root.`,
    }));
  },
});
