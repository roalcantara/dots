#!/usr/bin/env bun
// Every bootstrap step is a hidden task that takes `--profile <list>` (backed by DOTS_PROFILE, default desktop)
// via the shared `bootstrap_step` task template, and rejects unknown profile names before doing any work.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "step-profile-")));
  mkdirSync(join(t, "cfg"), { recursive: true });
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function runMiseStep(step: string, args: string[] = [], extraEnv: Record<string, string> = {}) {
  const p = Bun.spawnSync([MISE as string, "run", "-C", REPO, step, ...args], {
    cwd: REPO,
    env: {
      HOME: t,
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_GLOBAL_CONFIG_FILE: join(t, "cfg", "config.toml"),
      MISE_CEILING_PATHS: join(REPO, ".."),
      MISE_TRUSTED_CONFIG_PATHS: REPO,
      ...extraEnv,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode ?? 1, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe.skipIf(!MISE)("step --profile flag through real mise run", () => {
  it("a hidden step takes --profile dev", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\nname = test\n");
    const r = runMiseStep("bootstrap:git:home-config", ["--profile", "dev"]);
    expect(r.code, r.err).toBe(0);
    expect(r.err).toContain("~/.gitconfig overrides the dots git config");
  });

  it("a hidden step takes DOTS_PROFILE=desktop,dev", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\nname = test\n");
    const r = runMiseStep("bootstrap:git:home-config", [], { DOTS_PROFILE: "desktop,dev" });
    expect(r.code, r.err).toBe(0);
    expect(r.err).toContain("~/.gitconfig overrides the dots git config");
  });

  it("a hidden step defaults to desktop", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\nname = test\n");
    const r = runMiseStep("bootstrap:git:home-config");
    expect(r.code, r.err).toBe(0);
    expect(r.err).toContain("~/.gitconfig overrides the dots git config");
  });

  it("an invalid --profile fails before the step runs", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\nname = test\n");
    const r = runMiseStep("bootstrap:git:home-config", ["--profile", "devv"]);
    expect(r.code).not.toBe(0);
    expect(r.err).toContain("unknown profile");
    expect(r.err).not.toContain("~/.gitconfig overrides");
  });

  it("an invalid DOTS_PROFILE fails before the step runs", () => {
    writeFileSync(join(t, ".gitconfig"), "[user]\nname = test\n");
    const r = runMiseStep("bootstrap:git:home-config", [], { DOTS_PROFILE: "desktop,bogus" });
    expect(r.code).not.toBe(0);
    expect(r.err).toContain("unknown profile");
    expect(r.err).not.toContain("~/.gitconfig overrides");
  });
});
