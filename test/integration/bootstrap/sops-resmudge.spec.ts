#!/usr/bin/env bun
// setup:git:filters re-checks-out every filter=sops file once the filter exists, so a clone made before the age key
// (as install does) ends up with decrypted files. Throwaway key and repo only.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
const REPO = join(import.meta.dir, "../../..");
type MiseConfig = { tasks: Record<string, { run: string }> };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "mise.toml"), "utf8")) as MiseConfig;
const task = parsed.tasks["setup:git:filters"].run;
const SNIPPET = task.match(/# sops-resmudge: begin\n[\s\S]*?# sops-resmudge: end\n/)?.[0] ?? "";
const tools = ["git", "sops", "age-keygen", "age"].every((c) => Bun.which(c) !== null);

let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "sops-resmudge-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));

describe("setup:git:filters re-smudge", () => {
  it("is in the task, inside the configure branch", () => {
    expect(SNIPPET).toContain(":(attr:filter=sops)");
    expect(task.indexOf("# sops-resmudge: begin")).toBeGreaterThan(task.indexOf("git config --local filter.sops.clean"));
  });

  it.skipIf(!tools)("decrypts files a pre-filter clone left encrypted, mode 0600", () => {
    const cfg = join(t, "xdg");
    mkdirSync(join(cfg, "sops", "age"), { recursive: true });
    const key = join(cfg, "sops", "age", "keys.txt");
    Bun.spawnSync(["age-keygen", "-o", key], { stderr: "ignore" });
    const pub = Bun.spawnSync(["age-keygen", "-y", key]).stdout.toString().trim();
    const env = {
      PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, XDG_CONFIG_HOME: cfg, SOPS_AGE_KEY_FILE: key,
      GIT_CONFIG_GLOBAL: join(t, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1",
    };
    writeFileSync(env.GIT_CONFIG_GLOBAL, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n[init]\n  defaultBranch = main\n");
    const sh = (cwd: string, cmd: string) =>
      Bun.spawnSync(["bash", "-c", cmd], { cwd, env, stdout: "pipe", stderr: "pipe", timeout: 30_000 });

    const a = join(t, "a");
    mkdirSync(join(a, "script"), { recursive: true });
    mkdirSync(join(a, "secret"));
    for (const f of ["clean.sops.sh", "smudge.sops.sh"]) copyFileSync(join(REPO, "script", f), join(a, "script", f));
    writeFileSync(join(a, ".sops.yaml"), `creation_rules:\n  - path_regex: 'secret/.*'\n    age: ${pub}\n`);
    writeFileSync(join(a, ".gitattributes"), "secret/** filter=sops diff=sops\n");
    writeFileSync(join(a, "secret", "blob"), "plain-text-value\n");
    const setup = "git config --local filter.sops.smudge 'script/smudge.sops.sh %f' && git config --local filter.sops.required true && git config --local filter.sops.clean 'script/clean.sops.sh %f'";
    expect(sh(a, `git init -q && ${setup} && git add -A && git commit -q -m init`).exitCode).toBe(0);
    expect(sh(a, "git show HEAD:secret/blob").stdout.toString()).toContain("ENC[");

    // Clone without the filter (as install does), then configure it and run the snippet.
    const b = join(t, "b");
    expect(sh(t, `git clone -q ${a} ${b}`).exitCode).toBe(0);
    expect(readFileSync(join(b, "secret", "blob"), "utf8")).toContain("ENC[");
    const r = sh(b, `${setup}\n${SNIPPET}`);
    expect(r.exitCode).toBe(0);
    expect(readFileSync(join(b, "secret", "blob"), "utf8")).toBe("plain-text-value\n");
    expect(statSync(join(b, "secret", "blob")).mode & 0o077).toBe(0);
    expect(sh(b, "git status --porcelain").stdout.toString()).toBe("");
  });

  it.skipIf(!tools)("a file that does not decrypt is put back, the task fails and retries next time", () => {
    const cfg = join(t, "xdg");
    mkdirSync(join(cfg, "sops", "age"), { recursive: true });
    const key = join(cfg, "sops", "age", "keys.txt");
    Bun.spawnSync(["age-keygen", "-o", key], { stderr: "ignore" });
    const pub = Bun.spawnSync(["age-keygen", "-y", key]).stdout.toString().trim();
    const env = {
      PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: t, XDG_CONFIG_HOME: cfg, SOPS_AGE_KEY_FILE: key,
      GIT_CONFIG_GLOBAL: join(t, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1",
    };
    writeFileSync(env.GIT_CONFIG_GLOBAL, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n[init]\n  defaultBranch = main\n");
    const sh = (cwd: string, cmd: string, extra: Record<string, string> = {}) =>
      Bun.spawnSync(["bash", "-c", cmd], { cwd, env: { ...env, ...extra }, stdout: "pipe", stderr: "pipe", timeout: 30_000 });
    const a = join(t, "a");
    mkdirSync(join(a, "script"), { recursive: true });
    mkdirSync(join(a, "secret"));
    for (const f of ["clean.sops.sh", "smudge.sops.sh"]) copyFileSync(join(REPO, "script", f), join(a, "script", f));
    writeFileSync(join(a, ".sops.yaml"), `creation_rules:\n  - path_regex: 'secret/.*'\n    age: ${pub}\n`);
    writeFileSync(join(a, ".gitattributes"), "secret/** filter=sops diff=sops\n");
    writeFileSync(join(a, "secret", "blob"), "plain-text-value\n");
    const setup = "git config --local filter.sops.smudge 'script/smudge.sops.sh %f' && git config --local filter.sops.required true && git config --local filter.sops.clean 'script/clean.sops.sh %f'";
    expect(sh(a, `git init -q && ${setup} && git add -A && git commit -q -m init`).exitCode).toBe(0);
    const b = join(t, "b");
    expect(sh(t, `git clone -q ${a} ${b}`).exitCode).toBe(0);
    const before = readFileSync(join(b, "secret", "blob"), "utf8");

    // No key on this machine yet: the smudge cannot decrypt.
    renameSync(key, `${key}.away`);
    const r = sh(b, `${setup}\n${SNIPPET}`, { SOPS_AGE_KEY_FILE: `${key}.away.missing` });
    expect(r.exitCode).not.toBe(0);
    expect(r.stderr.toString()).toContain("could not decrypt: secret/blob");
    expect(readFileSync(join(b, "secret", "blob"), "utf8")).toBe(before);
    expect(sh(b, "git config --local --get filter.sops.clean").exitCode).not.toBe(0);
  });
});
