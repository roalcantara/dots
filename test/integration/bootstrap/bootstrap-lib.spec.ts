#!/usr/bin/env bun
// .mise/tasks/bootstrap/_lib.sh: profile validation/matching on usage_profile, platform guards, soft failures and logging.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const LIB = join(REPO, ".mise/tasks/bootstrap/_lib.sh");

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "bootstrap-lib-"));
  mkdirSync(join(t, "config", "mise"), { recursive: true });
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

// A bare environment: no DOTS_PROFILE or MISE_ENV leaks in from the caller.
function run(script: string, env: Record<string, string> = {}) {
  const p = Bun.spawnSync(["bash", "-c", script, "bash", LIB], {
    cwd: t,
    env: {
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      HOME: t,
      DOTS_DIR: t,
      ...env,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode ?? 1, out: p.stdout.toString().trim(), err: p.stderr.toString() };
}

describe("has_profile", () => {
  it("matches whole names split on commas or spaces", () => {
    const has = (name: string, val: string) =>
      run(`. "$1"; has_profile ${name} && echo yes || echo no`, { usage_profile: val }).out;
    expect(has("dev", "desktop,dev")).toBe("yes");
    expect(has("desktop", "desktop,dev")).toBe("yes");
    expect(has("dev", "desktop dev")).toBe("yes");
    expect(has("devops", "desktop,dev")).toBe("no");
    expect(has("container", "desktop,dev")).toBe("no");
  });

  it("ignores DOTS_PROFILE and MISE_ENV, defaulting to desktop when usage_profile is unset", () => {
    const has = (name: string, env: Record<string, string>) =>
      run(`. "$1"; has_profile ${name} && echo yes || echo no`, env).out;
    expect(has("desktop", { DOTS_PROFILE: "container", MISE_ENV: "dev" })).toBe("yes");
    expect(has("container", { DOTS_PROFILE: "container", MISE_ENV: "dev" })).toBe("no");
    expect(has("dev", { DOTS_PROFILE: "container", MISE_ENV: "dev" })).toBe("no");
  });

  it("exits 2 on a profile name outside desktop, dev, container", () => {
    const r = run('. "$1"; has_profile dev', { usage_profile: "desktop,devv" });
    expect(r.code).toBe(2);
    expect(r.err).toContain("unknown profile: devv");
  });

  it("names a * profile as given, not as the file names it would glob to", () => {
    const r = run('. "$1"; has_profile dev', { usage_profile: "*" });
    expect(r.code).toBe(2);
    expect(r.err).toContain("unknown profile: *");
  });
});

describe("warn", () => {
  it("continues and exits 0 normally", () => {
    const r = run('. "$1"; warn gopass; echo after');
    expect(r.code).toBe(0);
    expect(r.out).toBe("after");
    expect(r.err).toBe("bootstrap: gopass failed, continuing\n");
  });

  it("exits 1 under CI=1", () => {
    const r = run('. "$1"; warn gopass; echo after', { CI: "1" });
    expect(r.code).toBe(1);
    expect(r.out).toBe("");
    expect(r.err).toBe("bootstrap: gopass failed\n");
  });

  it("exits 1 under DOTS_STRICT=1", () => {
    const r = run('. "$1"; warn gopass; echo after', { DOTS_STRICT: "1" });
    expect(r.code).toBe(1);
    expect(r.err).toBe("bootstrap: gopass failed\n");
  });
});

describe("sourcing the library", () => {
  it("sets no shell options", () => {
    const r = run(
      'before_flags="$-"; before_opts="$(set +o)"; . "$1"; ' +
        '[ "$before_flags" = "$-" ] && [ "$before_opts" = "$(set +o)" ]',
    );
    expect(r.code).toBe(0);
  });
});
