import { defineRule } from "@archgate/core";

export default defineRule({
  name: "ARCH-002: provider-agnostic",
  description: "Provider modules must implement MusicianCore.Provider.Behaviour. Direct HTTP calls to provider APIs must go through the behaviour, not inline.",
  check({ files }) {
    const violations: Array<{ file: string; message: string }> = [];
    const providerFiles = files.filter(
      (f) =>
        f.path.includes("apps/musician_core/lib") &&
        f.path.includes("/provider/") &&
        f.path.endsWith(".ex") &&
        !f.path.includes("behaviour.ex") &&
        !f.path.includes("streaming.ex") &&
        !f.path.includes("request.ex") &&
        !f.path.includes("response.ex")
    );
    for (const f of providerFiles) {
      if (!f.content.includes("@behaviour MusicianCore.Provider.Behaviour")) {
        violations.push({
          file: f.path,
          message: `Provider module ${f.path} must declare @behaviour MusicianCore.Provider.Behaviour`,
        });
      }
    }
    return violations;
  },
});
