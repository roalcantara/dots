#!/usr/bin/env bun
// `mise run dots backup <action>` dispatches to `bun {{ vars.dots }}/script/backup.ts <action>` with
// validated action choices and documented flags (no `--` needed).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const TASKS_TOML = join(REPO, "config/mise/conf.d/tasks.toml");

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "dots-backup-")));
  mkdirSync(join(t, "bin"), { recursive: true });
  mkdirSync(join(t, "cfg", "conf.d"), { recursive: true });
  mkdirSync(join(t, "dots"), { recursive: true });
  mkdirSync(join(t, "cwd"), { recursive: true });

  writeFileSync(join(t, "cfg", "config.toml"), "");
  writeFileSync(join(t, "cfg", "conf.d", "vars.yaml"), "dots_dir: dots\n");
  writeFileSync(
    join(t, "cfg", "conf.d", "bootstrap.toml"),
    '[vars]\n_.file = "{{ mise_config_dir }}/conf.d/vars.yaml"\ndots = "{{ env.HOME }}/{{ vars.dots_dir }}"\n',
  );
  writeFileSync(join(t, "cfg", "conf.d", "tasks.toml"), readFileSync(TASKS_TOML, "utf8"));

  // Stub bun that records each argv element on its own line.
  writeFileSync(
    join(t, "bin", "bun"),
    `#!/bin/sh\nfor a in "$@"; do printf '%s\\n' "$a"; done > "${join(t, "bun.argv")}"\n`,
  );
  chmodSync(join(t, "bin", "bun"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function runBackup(args: string[]) {
  const p = Bun.spawnSync([MISE as string, "run", "-q", "dots", "backup", ...args], {
    cwd: join(t, "cwd"),
    env: {
      HOME: t,
      PATH: `${join(t, "bin")}:/usr/bin:/bin`,
      MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_TRUSTED_CONFIG_PATHS: t,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  const argv = existsSync(join(t, "bun.argv"))
    ? readFileSync(join(t, "bun.argv"), "utf8").trim().split("\n")
    : [];
  return { code: p.exitCode ?? 1, out: p.stdout.toString(), err: p.stderr.toString(), argv };
}

describe.skipIf(!MISE)("mise run dots backup", () => {
  it("restore --include Work --include Music --dry-run passes them to backup.ts restore", () => {
    const r = runBackup(["restore", "--include", "Work", "--include", "Music", "--dry-run"]);
    expect(r.code, r.err).toBe(0);
    expect(r.argv).toEqual([
      join(t, "dots", "script", "backup.ts"),
      "restore",
      "--include",
      "Work",
      "--include",
      "Music",
      "--dry-run",
    ]);
  });

  it("restore forwards --snapshot, --from-home and --target", () => {
    const r = runBackup([
      "restore",
      "--include",
      "Work",
      "--snapshot",
      "abc123",
      "--from-home",
      "/Users/old",
      "--target",
      "/tmp/out",
    ]);
    expect(r.code, r.err).toBe(0);
    expect(r.argv).toEqual([
      join(t, "dots", "script", "backup.ts"),
      "restore",
      "--include",
      "Work",
      "--snapshot",
      "abc123",
      "--from-home",
      "/Users/old",
      "--target",
      "/tmp/out",
    ]);
  });

  it("audit --stdout passes --stdout to backup.ts audit", () => {
    const r = runBackup(["audit", "--stdout"]);
    expect(r.code, r.err).toBe(0);
    expect(r.argv).toEqual([join(t, "dots", "script", "backup.ts"), "audit", "--stdout"]);
  });

  it("an unknown action fails before bun runs", () => {
    const r = runBackup(["bogus"]);
    expect(r.code).not.toBe(0);
    expect(r.argv).toEqual([]);
  });

  it("--help lists every action and flag", () => {
    const r = runBackup(["--help"]);
    expect(r.code, r.err).toBe(0);
    for (const action of ["init", "backup", "snapshots", "restore", "forget", "audit"]) {
      expect(r.out, `action ${action}`).toContain(action);
    }
    for (const flag of ["--include", "--snapshot", "--from-home", "--target", "--dry-run", "--stdout"]) {
      expect(r.out, `flag ${flag}`).toContain(flag);
    }
  });
});
