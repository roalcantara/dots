#!/usr/bin/env bun

import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

// Apple's /usr/bin/git is older than 2.54 and silently ignores config-based
// hooks. Every commit here goes through it deliberately: it is what VS Code and
// GUI clients get, and what the legacy shims must survive.
const APPLE_GIT = "/usr/bin/git";
const CLEAN_PATH = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin";

let repo: string;

function git(args: string[], env: Record<string, string> = {}) {
  return Bun.spawnSync([APPLE_GIT, ...args], {
    cwd: repo,
    stdout: "pipe",
    stderr: "pipe",
    env: { ...Bun.env, PATH: CLEAN_PATH, ...env },
  });
}

function commit(message: string, env: Record<string, string> = {}) {
  return git(["commit", "--allow-empty", "-m", message], env);
}

function stderrOf(r: { stderr: Uint8Array }) {
  return new TextDecoder().decode(r.stderr);
}

beforeAll(() => {
  repo = mkdtempSync(join(tmpdir(), "hk-hooks-"));
  for (const args of [
    ["init", "-q", "-b", "main", "."],
    ["config", "user.email", "test@example.com"],
    ["config", "user.name", "Test"],
    ["config", "commit.gpgsign", "false"],
  ]) {
    git(args);
  }
  writeFileSync(
    join(repo, "hk.pkl"),
    'amends "package://github.com/jdx/hk/releases/download/v1.56.0/hk@1.56.0#/Config.pkl"\n',
  );
  writeFileSync(join(repo, "mise.toml"), '[tools]\nhk = "1.56.0"\ncocogitto = "7.0.0"\n');
  const install = Bun.spawnSync(["hk", "install", "--mise", "--legacy", "--force-local"], {
    cwd: repo,
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(install.exitCode).toBe(0);
  git(["add", "-A"]);
  expect(commit("feat(hk): Add initial configuration").exitCode).toBe(0);
});

afterAll(() => rmSync(repo, { recursive: true, force: true }));

describe("hk git hooks", () => {
  describe("wiring", () => {
    it("installs a script shim rather than a config-based hook", () => {
      expect(Bun.file(join(repo, ".git/hooks/commit-msg")).size).toBeGreaterThan(0);
      expect(git(["config", "--get-regexp", "^hook\\."]).exitCode).not.toBe(0);
    });

    it("enforces rules under Apple git with hk absent from PATH", () => {
      const which = Bun.spawnSync(["sh", "-c", "command -v hk"], {
        env: { PATH: CLEAN_PATH },
        stdout: "pipe",
      });
      expect(which.exitCode).not.toBe(0);
      expect(commit("feat(cli): add lowercase").exitCode).not.toBe(0);
    });

    it("bypasses every hook when HK=0", () => {
      expect(commit("totally invalid message", { HK: "0" }).exitCode).toBe(0);
      git(["reset", "--hard", "HEAD~1"]);
    });
  });

  // Type and subject-style rules are covered exhaustively by `hk test` in
  // config/hk/config.pkl, which is ~7x faster per assertion. Only one of each
  // is asserted here, to prove the config is actually reaching the hook.
  describe("policy reaches the hook", () => {
    it("rejects refactor, proving the shared cog.toml is in effect", () => {
      expect(commit("refactor(nvim): Simplify keymaps").exitCode).not.toBe(0);
    });

    it("rejects an uncapitalized description", () => {
      expect(stderrOf(commit("feat(cli): add search command"))).toContain("capitalized");
    });
  });

  describe("machine-generated commits are exempt", () => {
    it("allows git merge --no-ff", () => {
      git(["checkout", "-q", "-b", "side"]);
      expect(commit("feat(b): Add side work").exitCode).toBe(0);
      git(["checkout", "-q", "main"]);
      expect(commit("feat(c): Add main work").exitCode).toBe(0);
      expect(git(["merge", "--no-ff", "-m", "Merge branch 'side'", "side"]).exitCode).toBe(0);
    });

    it("allows git revert of a normal commit", () => {
      writeFileSync(join(repo, "r.txt"), "x\n");
      git(["add", "-A"]);
      expect(git(["commit", "-m", "feat(r): Add a file to revert"]).exitCode).toBe(0);
      expect(git(["revert", "--no-edit", "HEAD"]).exitCode).toBe(0);
    });

    it("allows git commit --fixup", () => {
      writeFileSync(join(repo, "fx.txt"), "x\n");
      git(["add", "-A"]);
      expect(git(["commit", "--fixup", "HEAD"]).exitCode).toBe(0);
    });

    it("allows rebase --autosquash", () => {
      const r = git(["rebase", "--autosquash", "-i", "HEAD~2"], {
        GIT_SEQUENCE_EDITOR: "true",
      });
      expect(r.exitCode).toBe(0);
    });
  });
});
