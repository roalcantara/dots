#!/usr/bin/env bun
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, utimesSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const LIB = join(import.meta.dir, "../../../script/bootstrap-log.sh");
let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "bootstrap-log-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));
const logs = () => join(t, "state", "dots", "logs");

function run(body: string, env: Record<string, string> = {}) {
  const p = Bun.spawnSync(["bash", "-c", `. "${LIB}"\n${body}\nsleep 0.2`], {
    env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state"), ...env }, stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString() };
}

describe("bootstrap log", () => {
  it("tees output to a new dated log and links latest.log", () => {
    const r = run('echo "hello out"; echo "hello err" >&2');

    expect(r.out).toContain("hello out");
    const files = readdirSync(logs()).filter((f) => f.startsWith("bootstrap-"));
    expect(files.length).toBe(1);
    const text = readFileSync(join(logs(), files[0] as string), "utf8");
    expect(text).toContain("hello out");
    expect(text).toContain("hello err");
    expect(readlinkSync(join(logs(), "latest.log"))).toBe(files[0]);
  });

  // mise runs hooks with `sh`: bash 3.2 in POSIX mode on macOS (no process substitution), dash on Linux.
  it("tees when sourced by sh, as mise runs hooks", () => {
    const p = Bun.spawnSync(["sh", "-c", `. "${LIB}"\necho "from sh"; echo "err from sh" >&2\nsleep 0.2`], {
      env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state") }, stdout: "pipe", stderr: "pipe",
    });
    expect(p.exitCode).toBe(0);
    expect(p.stderr.toString()).not.toContain("syntax error");
    expect(p.stdout.toString()).toContain("from sh");
    const files = readdirSync(logs()).filter((f) => f.startsWith("bootstrap-"));
    const text = readFileSync(join(logs(), files[0] as string), "utf8");
    expect(text).toContain("from sh");
    expect(text).toContain("err from sh");
  });

  it("appends to DOTS_LOG when it is set", () => {
    mkdirSync(logs(), { recursive: true });
    const f = join(logs(), "bootstrap-20261104-000000.log");
    writeFileSync(f, "from install\n");
    run('echo "from hook"', { DOTS_LOG: f });
    expect(readFileSync(f, "utf8")).toBe("from install\nfrom hook\n");
  });

  it("adds no second tee when install already tees into DOTS_LOG", () => {
    mkdirSync(logs(), { recursive: true });
    const f = join(logs(), "bootstrap-20261104-000000.log");
    writeFileSync(f, "");
    // install's own tee, then the hook sourcing the script: each line must reach the log once.
    const p = Bun.spawnSync(["bash", "-c", `exec > >(tee -a "${f}") 2>&1; export DOTS_LOG_TEED=1; . "${LIB}"; echo "from hook"; sleep 0.2`], {
      env: { PATH: "/usr/bin:/bin", HOME: t, XDG_STATE_HOME: join(t, "state"), DOTS_LOG: f }, stdout: "pipe",
    });
    expect(p.exitCode).toBe(0);
    expect(readFileSync(f, "utf8")).toBe("from hook\n");
  });

  it("reuses latest.log written in the last 30 minutes (hook, then task, of one direct run)", () => {
    run('echo "hook"');
    run('echo "task"');
    const files = readdirSync(logs()).filter((f) => f.startsWith("bootstrap-"));
    expect(files.length).toBe(1);
    expect(readFileSync(join(logs(), files[0] as string), "utf8")).toBe("hook\ntask\n");
  });

  it("keeps the 10 newest logs", () => {
    mkdirSync(logs(), { recursive: true });
    for (let i = 0; i < 12; i++) {
      const f = join(logs(), `bootstrap-20260101-0000${String(i).padStart(2, "0")}.log`);
      writeFileSync(f, "old\n");
      const when = new Date(Date.now() - (60 + i) * 60_000); // older than 30 min, so not reused
      utimesSync(f, when, when);
    }
    run('echo "new"');
    expect(readdirSync(logs()).filter((f) => f.startsWith("bootstrap-")).length).toBe(10);
    expect(existsSync(join(logs(), "latest.log"))).toBe(true);
  });
});
