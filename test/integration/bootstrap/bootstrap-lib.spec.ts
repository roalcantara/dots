#!/usr/bin/env bun
// .mise/tasks/bootstrap/_lib.sh: the profile, platform guards, soft failures and logging every step shares.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
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

// A bare environment: no DOTS_PROFILE or MISE_ENV leaks in from the caller (mise sets MISE_ENV when it runs
// the specs), and HOME/DOTS_DIR point at the temp dir.
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

const profile = (env: Record<string, string> = {}) => run(`. "$1"; dots_profile`, { ...env }).out;

describe("dots_profile", () => {
  it("prefers DOTS_PROFILE, then MISE_ENV", () => {
    expect(profile({ DOTS_PROFILE: "dev", MISE_ENV: "desktop" })).toBe("dev");
    expect(profile({ MISE_ENV: "container" })).toBe("container");
  });

  it("reads -E from the parent command line", () => {
    // The parent is exec'd with mise bootstrap's argv. Its child sources the lib and prints the profile; the
    // trailing `; true` stops bash from exec-optimising the child away, which would hide the parent.
    const parent = join(t, "parent.sh");
    writeFileSync(
      parent,
      '#!/usr/bin/env bash\nexec -a "mise bootstrap -E desktop,dev --yes" bash -c \'bash -c ". \\"$1\\"; dots_profile" _ "$1"; true\' _ "$1"\n',
    );
    const p = Bun.spawnSync(["bash", parent, LIB], {
      cwd: t,
      env: { PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, DOTS_DIR: t },
      stdin: "ignore",
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(p.exitCode).toBe(0);
    expect(p.stdout.toString().trim()).toBe("desktop,dev");
  });

  it("reads miserc.local.toml", () => {
    writeFileSync(join(t, "config", "mise", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    expect(profile()).toBe("desktop,dev");
  });

  it("defaults to desktop", () => {
    expect(profile()).toBe("desktop");
  });
});

describe("has_profile", () => {
  it("matches whole names only", () => {
    const has = (name: string) =>
      run(`. "$1"; has_profile ${name} && echo yes || echo no`, { DOTS_PROFILE: "desktop,dev" }).out;
    expect(has("dev")).toBe("yes");
    expect(has("desktop")).toBe("yes");
    expect(has("devops")).toBe("no");
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
