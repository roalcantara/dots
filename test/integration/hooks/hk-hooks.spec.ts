#!/usr/bin/env bun

import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { join, resolve } from "node:path";
import { tmpdir } from "node:os";

// Apple's /usr/bin/git is older than 2.54 and silently ignores config-based
// hooks. Every commit here goes through it deliberately: it is what VS Code and
// GUI clients get, and what the legacy shims must survive.
const APPLE_GIT = "/usr/bin/git";
const configDir = resolve(import.meta.dir, "../../../config");
let repo: string;
let cleanBin: string;
let cleanPath: string;
let testConfigDir: string;

function git(args: string[], env: Record<string, string> = {}) {
  return Bun.spawnSync([APPLE_GIT, ...args], {
    cwd: repo,
    stdout: "pipe",
    stderr: "pipe",
    env: { ...Bun.env, PATH: cleanPath, XDG_CONFIG_HOME: testConfigDir, ...env },
  });
}

function commit(message: string, env: Record<string, string> = {}) {
  return git(["commit", "--allow-empty", "-m", message], env);
}

beforeAll(() => {
  repo = mkdtempSync(join(tmpdir(), "hk-hooks-"));
  cleanBin = mkdtempSync(join(tmpdir(), "hk-clean-bin-"));
  symlinkSync(Bun.which("mise") ?? "/opt/homebrew/bin/mise", join(cleanBin, "mise"));
  cleanPath = `${cleanBin}:/usr/bin:/bin:/usr/sbin:/sbin`;

  // Only the global hk config under test, never the rest of the live config/ (git signing, mise, ...).
  testConfigDir = mkdtempSync(join(tmpdir(), "hk-config-"));
  symlinkSync(join(configDir, "hk"), join(testConfigDir, "hk"));

  for (const args of [
    ["init", "-q", "-b", "main", "."],
    ["config", "user.email", "test@example.com"],
    ["config", "user.name", "Test"],
    ["config", "commit.gpgsign", "false"],
  ]) {
    git(args);
  }
  // The global config defines no hooks, so the repo declares one: a subject must start with "ok:".
  writeFileSync(
    join(repo, "hk.pkl"),
    [
      'amends "package://github.com/jdx/hk/releases/download/v2.0.1/hk@2.0.1#/Config.pkl"',
      'hooks { ["commit-msg"] { steps { ["subject"] { check = "grep -q \'^ok:\' {{commit_msg_file}}" } } } }',
      "",
    ].join("\n"),
  );
  writeFileSync(join(repo, "mise.toml"), '[tools]\nhk = "2.6.0"\n');
  const install = Bun.spawnSync(["hk", "install", "--mise", "--legacy", "--force-local"], {
    cwd: repo,
    env: { ...Bun.env, XDG_CONFIG_HOME: testConfigDir },
    stdout: "pipe",
  });
  expect(install.exitCode).toBe(0);
  git(["add", "-A"]);
  expect(commit("ok: initial configuration").exitCode).toBe(0);
  // A cold first run (mise resolving hk, hk fetching its pkl packages) can take longer than bun's 5 s default.
}, 60_000);

afterAll(() => {
  rmSync(repo, { recursive: true, force: true });
  rmSync(cleanBin, { recursive: true, force: true });
  rmSync(testConfigDir, { recursive: true, force: true });
});

describe("hk git hooks", () => {
  describe("wiring", () => {
    it("installs a script shim rather than a config-based hook", () => {
      expect(Bun.file(join(repo, ".git/hooks/commit-msg")).size).toBeGreaterThan(0);
      expect(git(["config", "--get-regexp", "^hook\\."]).exitCode).not.toBe(0);
    });

    it("enforces rules under Apple git with hk absent from PATH", () => {
      const which = Bun.spawnSync(["sh", "-c", "command -v hk"], {
        env: { PATH: cleanPath },
        stdout: "pipe",
      });
      expect(which.exitCode).not.toBe(0);
      expect(commit("feat(cli): Not ok").exitCode).not.toBe(0);
      expect(commit("ok: accepted").exitCode).toBe(0);
    });

    it("bypasses every hook when HK=0", () => {
      expect(commit("totally invalid message", { HK: "0" }).exitCode).toBe(0);
      git(["reset", "--hard", "HEAD~1"]);
    });
  });

  // config/hk/config.pkl is merged into every repository on the machine: a hook there would gate
  // commits in repos that never asked for it (and need its tools, e.g. cog, installed globally).
  it("the global config defines no hooks", () => {
    expect(readFileSync(join(configDir, "hk", "config.pkl"), "utf8")).not.toMatch(/^\s*hooks\s*\{/m);
  });
});
