#!/usr/bin/env bun
// The SOPS filter scripts tell sops where the age key is. A fresh install has only HOME set: without
// SOPS_AGE_KEY_FILE, sops on macOS looks in ~/Library/Application Support/sops/age/keys.txt and fails
// ("Failed to get the data key required to decrypt the SOPS file"). Throwaway key only.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { copyFileSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const tools = ["sops", "age-keygen", "age"].every((c) => Bun.which(c) !== null);

let t: string;
beforeEach(() => (t = mkdtempSync(join(tmpdir(), "sops-key-path-"))));
afterEach(() => rmSync(t, { recursive: true, force: true }));

describe.skipIf(!tools)("SOPS filter scripts", () => {
  it("decrypt with only HOME set, from ~/.config/sops/age/keys.txt", () => {
    const home = join(t, "home");
    const key = join(home, ".config", "sops", "age", "keys.txt");
    mkdirSync(join(home, ".config", "sops", "age"), { recursive: true });
    Bun.spawnSync(["age-keygen", "-o", key], { stderr: "ignore" });
    const pub = Bun.spawnSync(["age-keygen", "-y", key]).stdout.toString().trim();
    const repo = join(t, "repo");
    mkdirSync(join(repo, "script"), { recursive: true });
    copyFileSync(join(REPO, "script", "smudge.sops.sh"), join(repo, "script", "smudge.sops.sh"));
    writeFileSync(join(repo, ".sops.yaml"), `creation_rules:\n  - path_regex: '.*'\n    age: ${pub}\n`);
    writeFileSync(join(t, "plain"), "secret-value\n");
    const enc = Bun.spawnSync(["sops", "encrypt", "--input-type", "binary", "--output-type", "json", "--age", pub, join(t, "plain")], {
      // From the temp dir: run inside this repo, sops would pick up the repo's .sops.yaml.
      cwd: t, env: { PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: home, SOPS_AGE_KEY_FILE: key },
    }).stdout;
    expect(enc.length).toBeGreaterThan(0);
    // Only PATH and HOME, as on a fresh machine: no XDG_CONFIG_HOME, no SOPS_AGE_KEY_FILE.
    const p = Bun.spawnSync(["bash", "script/smudge.sops.sh", "secret.bin"], {
      cwd: repo, env: { PATH: process.env.PATH ?? "/usr/bin:/bin", HOME: home }, stdin: enc, stdout: "pipe", stderr: "pipe",
    });
    expect(p.stderr.toString()).not.toContain("Failed to get the data key");
    expect(p.exitCode).toBe(0);
    expect(p.stdout.toString()).toBe("secret-value\n");
  });
});
