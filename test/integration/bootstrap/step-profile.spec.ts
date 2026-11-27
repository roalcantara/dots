#!/usr/bin/env bun
// Every bootstrap step is a hidden task that takes `--profile <list>` (backed by DOTS_PROFILE; else mise_env, else desktop)
// via the shared `bootstrap_step` task template (config/mise/conf.d/tasks.toml), and rejects unknown profile
// names before doing any work.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { tasksToml } from "./parts";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "step-profile-")));
  mkdirSync(join(t, "cfg"), { recursive: true });
  // The shared template is global (config/mise/conf.d/tasks.toml); without it the steps do not load. Copy that table.
  const { usage, env } = tasksToml().task_templates.bootstrap_step;
  writeFileSync(
    join(t, "cfg", "config.toml"),
    `[task_templates.bootstrap_step]\nenv = { DOTS_ENV_PROFILES = '${env.DOTS_ENV_PROFILES}' }\nusage = '''\n${usage}'''\n`,
  );
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

  it("a hidden step with no --profile and no (or an empty) DOTS_PROFILE uses mise_env from miserc.local.toml", () => {
    mkdirSync(join(t, "bin"), { recursive: true });
    // Stub brew (so bootstrap_init does not prepend real Homebrew) and uv (to record calls).
    writeFileSync(join(t, "bin", "brew"), "#!/bin/sh\nexit 0\n");
    writeFileSync(join(t, "bin", "uv"), `#!/bin/sh\necho "uv $*" >> "${join(t, "uv.log")}"\nexit 0\n`);
    for (const b of ["brew", "uv"]) chmodSync(join(t, "bin", b), 0o755);
    const stubPath = `${join(t, "bin")}:/usr/bin:/bin`;

    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    const r = runMiseStep("bootstrap:dev:python-tools", [], { PATH: stubPath });
    expect(r.code, r.err).toBe(0);
    expect(existsSync(join(t, "uv.log"))).toBe(true);
    expect(readFileSync(join(t, "uv.log"), "utf8")).toContain("uv tool install");

    // An empty DOTS_PROFILE counts as unset, as in `dots setup`.
    rmSync(join(t, "uv.log"), { force: true });
    const empty = runMiseStep("bootstrap:dev:python-tools", [], { PATH: stubPath, DOTS_PROFILE: "" });
    expect(empty.code, empty.err).toBe(0);
    expect(existsSync(join(t, "uv.log"))).toBe(true);

    // Non-profile env in miserc.local.toml is ignored; without dev, python-tools does nothing.
    rmSync(join(t, "uv.log"), { force: true });
    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "macos"]\n');
    const noDev = runMiseStep("bootstrap:dev:python-tools", [], { PATH: stubPath });
    expect(noDev.code, noDev.err).toBe(0);
    expect(existsSync(join(t, "uv.log"))).toBe(false);
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
