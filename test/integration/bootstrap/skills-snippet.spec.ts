#!/usr/bin/env bun
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");

type BootstrapConfig = { tasks: { bootstrap: { run: string } } };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as BootstrapConfig;
const task = parsed.tasks.bootstrap.run;
const SNIPPET = task.match(/# skills: begin\n[\s\S]*?# skills: end\n/)?.[0] ?? "";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "skills-snippet-"));
  mkdirSync(join(t, "bin"));
  // A stub mise that records its arguments and takes 2 s, like a slow restore.
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" >> "${join(t, "calls")}"\nsleep 2\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const started = Date.now();
  const p = Bun.spawnSync(["bash", "-c", `dots=/repo\ndev=\${DEV:-true}\nwarn() { echo "warn $1" >&2; }\n${SNIPPET}`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, XDG_STATE_HOME: join(t, "state"), ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), ms: Date.now() - started };
}

describe("bootstrap skills snippet", () => {
  it("is in the bootstrap task", () => expect(SNIPPET).toContain("--background"));

  it("does nothing without the dev profile", () => {
    const r = snippet({ DEV: "false" });
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
const PYTHON = task.match(/# dev-python: begin\n[\s\S]*?# dev-python: end\n/)?.[0] ?? "";

describe("bootstrap dev-python snippet", () => {
  function python(dev: string) {
    writeFileSync(join(t, "bin", "uv"), `#!/bin/sh\necho "uv $*" >> "${join(t, "uv.log")}"\nexit 0\n`);
    chmodSync(join(t, "bin", "uv"), 0o755);
    Bun.spawnSync(["bash", "-c", `dev=${dev}\nwarn() { :; }\n${PYTHON}`], { env: { PATH: `${join(t, "bin")}:/usr/bin:/bin` } });
    return existsSync(join(t, "uv.log")) ? readFileSync(join(t, "uv.log"), "utf8") : "";
  }
  it("is in the bootstrap task", () => expect(PYTHON).toContain("graphifyy"));
  it("installs both tools with dev", () => {
    const log = python("true");
    expect(log).toContain("uv tool install --python 3.13 graphifyy");
    expect(log).toContain("uv tool install --python 3.13 code-review-graph");
  });
  it("does nothing without dev", () => expect(python("false")).toBe(""));
});
