#!/usr/bin/env bun
// The skills-restore and dev-python steps: the dev profile gates them, the restore runs in the background, and both
// only warn on failure.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "skills-snippet-"));
  mkdirSync(join(t, "bin"));
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  writeFileSync(join(t, "bin", "brew"), "#!/bin/sh\nexit 0\n");
  chmodSync(join(t, "bin", "brew"), 0o755);
  // A stub mise that records its arguments and takes 2 s, like a slow restore.
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" >> "${join(t, "calls")}"\nsleep 2\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const started = Date.now();
  const r = runStep("skills/restore.sh", {
    PATH: `${join(t, "bin")}:/usr/bin:/bin`,
    HOME: t,
    XDG_STATE_HOME: join(t, "state"),
    usage_profile: "desktop,dev",
    ...env,
  });
  return { code: r.code, out: r.out, ms: Date.now() - started };
}

describe("bootstrap skills step", () => {
  it("is in the final phase, in the background", () => {
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap/skills/restore.sh"), "utf8")).toContain("--background");
  });

  it("does nothing without the dev profile", () => {
    const r = snippet({ usage_profile: "desktop" });
    expect(r.code).toBe(0);
    expect(r.out).not.toContain("restoring agent skills");
    expect(existsSync(join(t, "calls"))).toBe(false);
  });

  it("returns at once and points at the log", () => {
    const r = snippet();
    expect(r.code).toBe(0);
    expect(r.ms).toBeLessThan(1500);
    expect(r.out).toContain("restoring agent skills in the background");
    expect(r.out).toContain(join(t, "state", "dots", "skills-restore.log"));
  });

  it("DOTS_SKILLS_FOREGROUND=1 waits for the restore", () => {
    const r = snippet({ DOTS_SKILLS_FOREGROUND: "1" });
    expect(r.ms).toBeGreaterThanOrEqual(2000);
    expect(readFileSync(join(t, "calls"), "utf8")).toContain("skills:restore");
  });
});

// The Python 3.13 tools (graphifyy, code-review-graph): dev only.
describe("bootstrap dev-python step", () => {
  it("is in the final phase, for the dev profile", () => {
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap/dev/python-tools.sh"), "utf8")).toContain("graphifyy");
  });

  function python(profile: string) {
    writeFileSync(join(t, "bin", "uv"), `#!/bin/sh\necho "uv $*" >> "${join(t, "uv.log")}"\nexit 0\n`);
    chmodSync(join(t, "bin", "uv"), 0o755);
    runStep("dev/python-tools.sh", { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, usage_profile: profile });
    return existsSync(join(t, "uv.log")) ? readFileSync(join(t, "uv.log"), "utf8") : "";
  }

  it("installs both tools with dev", () => {
    const log = python("desktop,dev");
    expect(log).toContain("uv tool install --python 3.13 graphifyy");
    expect(log).toContain("uv tool install --python 3.13 code-review-graph");
  });

  it("does nothing without dev", () => expect(python("desktop")).toBe(""));
});
