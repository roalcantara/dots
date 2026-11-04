#!/usr/bin/env bun
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
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
  const p = Bun.spawnSync(["bash", "-c", `dots=/repo\nwarn() { echo "warn $1" >&2; }\n${SNIPPET}`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, XDG_STATE_HOME: join(t, "state"), ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), ms: Date.now() - started };
}

describe("bootstrap skills snippet", () => {
  it("is in the bootstrap task", () => expect(SNIPPET).toContain("--background"));

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
