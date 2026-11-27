#!/usr/bin/env bun
// The `dots` front door (`config/mise/conf.d/tasks.toml`): `dots setup` runs selected parts in fixed order
// (or all parts when none are given), followed by `dots:setup:remind`, rejects unknown flags or profiles
// before any part runs, and forwards the parsed profile as DOTS_PROFILE.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const TASKS_TOML = join(REPO, "config/mise/conf.d/tasks.toml");

const ALL_PARTS = [
  "brew",
  "yabai",
  "app-files",
  "vscode",
  "bat",
  "lig",
  "macos",
  "swiftbar",
  "git",
  "shell",
  "dev",
  "secrets",
  "tiling",
  "ai",
  "skills",
  "nvim",
];

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "dots-setup-")));
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

  // Stub repo with hidden dots:setup:<part> tasks that log "<part>:<DOTS_PROFILE>" to $t/ran.
  const stubTasks = [...ALL_PARTS, "remind"]
    .map(
      (p) =>
        `[tasks."dots:setup:${p}"]\nhide = true\nrun = 'printf "%s:%s\\n" "${p}" "\${DOTS_PROFILE:-<unset>}" >> "${join(t, "ran")}"'\n`,
    )
    .join("\n");
  writeFileSync(join(t, "dots", "mise.toml"), stubTasks);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function runDots(args: string[], extraEnv: Record<string, string> = {}) {
  const p = Bun.spawnSync([MISE as string, "run", "-q", "dots", ...args], {
    cwd: join(t, "cwd"),
    env: {
      HOME: t,
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_TRUSTED_CONFIG_PATHS: t,
      ...extraEnv,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  const ran = existsSync(join(t, "ran")) ? readFileSync(join(t, "ran"), "utf8").trim().split("\n") : [];
  return { code: p.exitCode ?? 1, out: p.stdout.toString(), err: p.stderr.toString(), ran };
}

describe.skipIf(!MISE)("mise run dots setup", () => {
  it("no flags runs every part in order, then remind", () => {
    const r = runDots(["setup"]);
    expect(r.code, r.err).toBe(0);
    expect(r.ran.map((l) => l.split(":")[0])).toEqual([...ALL_PARTS, "remind"]);
  });

  it("--git --brew runs brew then git then remind (fixed order, not flag order)", () => {
    const r = runDots(["setup", "--git", "--brew"]);
    expect(r.code, r.err).toBe(0);
    expect(r.ran.map((l) => l.split(":")[0])).toEqual(["brew", "git", "remind"]);
  });

  it("--brw fails before any part runs", () => {
    const r = runDots(["setup", "--brw"]);
    expect(r.code).not.toBe(0);
    expect(r.ran).toEqual([]);
  });

  it("--profile devv and --profile devops exit 2 before any part runs", () => {
    for (const bad of ["devv", "devops"]) {
      const r = runDots(["setup", "--profile", bad, "--brew"]);
      expect(r.code).toBe(2);
      expect(r.err).toContain(`unknown profile: ${bad}`);
      expect(r.ran).toEqual([]);
    }
  });

  it("DOTS_PROFILE=desktop,dev is accepted by dots setup", () => {
    const r = runDots(["setup", "--bat"], { DOTS_PROFILE: "desktop,dev" });
    expect(r.code, r.err).toBe(0);
    expect(r.ran).toEqual(["bat:desktop,dev", "remind:desktop,dev"]);
  });

  it("when neither --profile nor DOTS_PROFILE is given, uses mise_env from miserc.local.toml (filtered) or defaults to desktop", () => {
    // No miserc -> defaults to desktop
    const def = runDots(["setup", "--dev"]);
    expect(def.code, def.err).toBe(0);
    expect(def.ran).toEqual(["dev:desktop", "remind:desktop"]);

    // miserc with desktop + dev -> DOTS_PROFILE=desktop,dev
    rmSync(join(t, "ran"), { force: true });
    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    const dev = runDots(["setup", "--dev"]);
    expect(dev.code, dev.err).toBe(0);
    expect(dev.ran).toEqual(["dev:desktop,dev", "remind:desktop,dev"]);

    // miserc with non-profile env -> filters to known profiles only
    rmSync(join(t, "ran"), { force: true });
    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "macos"]\n');
    const filtered = runDots(["setup", "--dev"]);
    expect(filtered.code, filtered.err).toBe(0);
    expect(filtered.ran).toEqual(["dev:desktop", "remind:desktop"]);
  });

  it("--profile dev reaches the parts as DOTS_PROFILE=dev, and multiple --profile join with commas", () => {
    const single = runDots(["setup", "--brew", "--profile", "dev"]);
    expect(single.code, single.err).toBe(0);
    expect(single.ran).toEqual(["brew:dev", "remind:dev"]);

    rmSync(join(t, "ran"), { force: true });
    const multi = runDots(["setup", "--brew", "--profile", "desktop", "--profile", "dev"]);
    expect(multi.code, multi.err).toBe(0);
    expect(multi.ran).toEqual(["brew:desktop,dev", "remind:desktop,dev"]);
  });

  it("mise run dots setup --help lists every part flag with its help, and --profile", () => {
    const r = runDots(["setup", "--help"]);
    expect(r.code, r.err).toBe(0);
    for (const part of ALL_PARTS) {
      expect(r.out, `--${part} in help`).toContain(`--${part}`);
    }
    expect(r.out).toContain("--profile");
  });
});
