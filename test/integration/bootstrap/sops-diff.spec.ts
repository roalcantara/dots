#!/usr/bin/env bun
// git diff shows SOPS files decrypted through diff.sops.textconv (script/textconv.sops.sh). The old
// diff.sops.command "script/smudge.sops.sh %f" hung: git calls a diff command with seven arguments and nothing on
// stdin. setup:git:filters sets the textconv on every run, so existing clones drop the old line. Throwaway key only.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
type MiseConfig = { tasks: Record<string, { run: string }> };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "mise.toml"), "utf8")) as MiseConfig;
const task = parsed.tasks["setup:git:filters"]?.run ?? "";
const SNIPPET = task.match(/# sops-diff: begin\n[\s\S]*?# sops-diff: end\n/)?.[0] ?? "";
const tools = ["git", "sops", "age-keygen", "age"].every((c) => Bun.which(c) !== null);

let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "sops-diff-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));

describe("setup:git:filters diff driver", () => {
  it("sets the textconv on every run, never caches it, and drops the old command", () => {
    expect(SNIPPET).toContain('git config --local diff.sops.textconv "script/textconv.sops.sh"');
    expect(SNIPPET).toContain("git config --local diff.sops.cachetextconv false");
    expect(SNIPPET).toContain("--unset diff.sops.command");
    // Outside the branch that runs only once (when the filter isn't configured yet).
    expect(task.indexOf("# sops-diff: begin")).toBeLessThan(task.indexOf("if [ -f"));
    expect(task).not.toContain('diff.sops.command "script/smudge.sops.sh %f"');
  });

  it.skipIf(!tools)("makes git diff show a changed secret decrypted, without hanging", () => {
    const cfg = join(t, "xdg");
    mkdirSync(join(cfg, "sops", "age"), { recursive: true });
    const key = join(cfg, "sops", "age", "keys.txt");
    Bun.spawnSync(["age-keygen", "-o", key], { stderr: "ignore" });
    const pub = Bun.spawnSync(["age-keygen", "-y", key]).stdout.toString().trim();
    const env = {
      PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, XDG_CONFIG_HOME: cfg, SOPS_AGE_KEY_FILE: key,
      GIT_CONFIG_GLOBAL: join(t, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1", GIT_PAGER: "cat",
    };
    writeFileSync(env.GIT_CONFIG_GLOBAL, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n[init]\n  defaultBranch = main\n");
    const sh = (cmd: string) =>
      Bun.spawnSync(["bash", "-c", cmd], { cwd: repo, env, stdout: "pipe", stderr: "pipe", timeout: 30_000 });

    const repo = join(t, "repo");
    mkdirSync(join(repo, "script"), { recursive: true });
    for (const s of ["clean.sops.sh", "smudge.sops.sh", "textconv.sops.sh"]) {
      copyFileSync(join(REPO, "script", s), join(repo, "script", s));
    }
    writeFileSync(join(repo, ".sops.yaml"), `creation_rules:\n  - path_regex: '.*\\.env$'\n    age: ${pub}\n    encrypted_regex: '^.*SECRET.*$'\n`);
    writeFileSync(join(repo, ".gitattributes"), "*.env filter=sops diff=sops\n");
    expect(sh("git init -q && git config filter.sops.clean 'script/clean.sops.sh %f' && git config filter.sops.smudge 'script/smudge.sops.sh %f' && git config filter.sops.required true").exitCode).toBe(0);
    // A clone configured before the fix: the old, hanging command.
    sh("git config diff.sops.command 'script/smudge.sops.sh %f'");
    expect(sh(SNIPPET).exitCode).toBe(0);
    expect(sh("git config --get diff.sops.command").exitCode).not.toBe(0);

    writeFileSync(join(repo, "a.env"), "APP_SECRET=one\nDEBUG=true\n");
    expect(sh("git add . && git commit -qm init").exitCode).toBe(0);
    expect(sh("git show HEAD:a.env").stdout.toString()).toContain("ENC[AES256_GCM");
    writeFileSync(join(repo, "a.env"), "APP_SECRET=two\nDEBUG=true\n");
    const diff = sh("git diff");
    expect(diff.exitCode).toBe(0);
    expect(diff.stdout.toString()).toContain("-APP_SECRET=one");
    expect(diff.stdout.toString()).toContain("+APP_SECRET=two");
  });

  it.skipIf(!tools)("prints what it can't decrypt as it is (the plain working-tree side, or no key)", () => {
    const plain = join(t, "plain.env");
    writeFileSync(plain, "DEBUG=true\n");
    const run = (file: string, env: Record<string, string>) =>
      Bun.spawnSync(["bash", join(REPO, "script", "textconv.sops.sh"), file], { env, stdout: "pipe", stderr: "pipe" });
    const noKey = { PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, XDG_CONFIG_HOME: join(t, "none") };
    const p = run(plain, noKey);
    expect(p.exitCode).toBe(0);
    expect(p.stdout.toString()).toBe("DEBUG=true\n");
  });
});
