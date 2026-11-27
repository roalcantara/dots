#!/usr/bin/env bun
// Doctor checks under .mise/tasks/doctor/: each runs only under the container profile, prints "does not apply"
// elsewhere, and derives its assertions from the Brewfile, step headers, or .gitattributes.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { tasksToml } from "./parts";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const CHECKS = ["doctor:container-tools", "doctor:profile-parts", "doctor:sops-encrypted"];

let t: string;

beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "doctor-checks-")));
  mkdirSync(join(t, "cfg"), { recursive: true });
  const { usage, env } = tasksToml().task_templates.bootstrap_step;
  writeFileSync(
    join(t, "cfg", "config.toml"),
    `[task_templates.bootstrap_step]\nenv = { DOTS_ENV_PROFILES = '${env.DOTS_ENV_PROFILES}' }\nusage = '''\n${usage}'''\n`,
  );
});

afterEach(() => rmSync(t, { recursive: true, force: true }));

function runCheck(task: string, extraEnv: Record<string, string> = {}) {
  const p = Bun.spawnSync([MISE as string, "run", "-C", REPO, task], {
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

function setProfile(profiles: string[]) {
  writeFileSync(join(t, "cfg", "miserc.local.toml"), `env = [${profiles.map((p) => `"${p}"`).join(", ")}]\n`);
}

function writeStub(dir: string, name: string, body: string) {
  mkdirSync(dir, { recursive: true });
  const path = join(dir, name);
  writeFileSync(path, `#!/usr/bin/env bash\n${body}\n`);
  chmodSync(path, 0o755);
  return path;
}

describe.skipIf(!MISE)("doctor checks", () => {
  it("each check does not apply outside the container profile", () => {
    setProfile(["desktop", "dev"]);
    for (const task of CHECKS) {
      const r = runCheck(task);
      expect(r.code, `${task}: ${r.err}`).toBe(0);
      expect(r.out, task).toContain("does not apply");
    }
  });

  it("container-tools fails when brew bundle check fails, and passes when it succeeds", () => {
    setProfile(["container"]);
    const binDir = join(t, "bin");
    // Minimal ZDOTDIR so zsh -lic does not read real user dotfiles and keeps our stub PATH after /etc/zprofile.
    const zdot = join(t, "zdot");
    mkdirSync(zdot, { recursive: true });
    writeFileSync(join(zdot, ".zprofile"), `export PATH="${binDir}:/usr/bin:/bin"\n`);
    writeStub(
      binDir,
      "brew",
      `if [ "\${1:-}" = "bundle" ] && [ "\${2:-}" = "check" ]; then
  exit \${STUB_BREW_EXIT:-0}
fi
exit 0`,
    );

    const fail = runCheck("doctor:container-tools", {
      ZDOTDIR: zdot,
      DOTS_DIR: REPO,
      STUB_BREW_EXIT: "1",
    });
    expect(fail.code).not.toBe(0);

    const pass = runCheck("doctor:container-tools", {
      ZDOTDIR: zdot,
      DOTS_DIR: REPO,
      STUB_BREW_EXIT: "0",
    });
    expect(pass.code, pass.err).toBe(0);
  });

  it("profile-parts fails naming a present artifact, passes when none exists", () => {
    setProfile(["container"]);
    const pass = runCheck("doctor:profile-parts", { DOTS_DIR: REPO });
    expect(pass.code, pass.err).toBe(0);

    // Create an artifact declared by .mise/tasks/bootstrap/skills/restore.sh.
    mkdirSync(join(t, ".agents/skills"), { recursive: true });
    const fail = runCheck("doctor:profile-parts", { DOTS_DIR: REPO });
    expect(fail.code).not.toBe(0);
    expect(fail.err).toContain(".agents/skills");
    expect(fail.err).toContain("skills/restore.sh");
  });

  it("sops-encrypted fails naming a plain-text file, passes on an encrypted one", () => {
    setProfile(["container"]);
    const repo = join(t, "repo");
    mkdirSync(join(repo, "secrets"), { recursive: true });
    writeFileSync(join(repo, ".gitattributes"), "secrets/*.key filter=sops diff=sops\n");
    writeFileSync(join(repo, "secrets/test.key"), "ENC[AES256_GCM,data:abc,iv:def,tag:ghi,type:str]\n");
    const git = (...args: string[]) => {
      const p = Bun.spawnSync(["git", ...args], { cwd: repo, stdout: "pipe", stderr: "pipe" });
      if (p.exitCode !== 0) throw new Error(p.stderr.toString());
    };
    git("init", "-q");
    git("add", ".gitattributes", "secrets/test.key");

    const pass = runCheck("doctor:sops-encrypted", { DOTS_DIR: repo });
    expect(pass.code, pass.err).toBe(0);

    writeFileSync(join(repo, "secrets/test.key"), "BEGIN OPENSSH PRIVATE KEY\nplain text\n");
    const fail = runCheck("doctor:sops-encrypted", { DOTS_DIR: repo });
    expect(fail.code).not.toBe(0);
    expect(fail.err).toContain("secrets/test.key");
  });
});
