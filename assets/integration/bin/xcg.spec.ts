#!/usr/bin/env bun
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { type GitFixture, makeGitFixture } from "./support/git-fixture";
import { scriptPath } from "./support/paths";

let fx: GitFixture;

beforeAll(() => { fx = makeGitFixture(); });
afterAll(() => { fx.cleanup(); });

describe("git-fixture", () => {
  it("creates the expected branch states", () => {
    const r = Bun.spawnSync(["git", "branch", "--format=%(refname:short)"], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    const branches = new TextDecoder().decode(r.stdout).trim().split("\n").sort();
    expect(branches).toEqual(["gone-branch", "main", "merged-branch", "unmerged-branch"]);
  });

  it("has a remote-only branch", () => {
    const r = Bun.spawnSync(["git", "for-each-ref", "--format=%(refname:short)", "refs/remotes"], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    expect(new TextDecoder().decode(r.stdout)).toContain("origin/remote-only");
  });
});

const script = scriptPath("xcg");

function xcg(args: string[], cwd = fx.work) {
  const r = Bun.spawnSync([script, ...args], { cwd, stdout: "pipe", stderr: "pipe" });
  return {
    code: r.exitCode,
    out: new TextDecoder().decode(r.stdout),
    err: new TextDecoder().decode(r.stderr),
  };
}

describe("xcg help and public subcommands", () => {
  it("prints help with -h and exits 0", () => {
    const r = xcg(["-h"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("xcg");
  });

  it("prints help with --help and exits 0", () => {
    const r = xcg(["--help"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("xcg");
  });

  it("documents the fzf keymap in help", () => {
    expect(xcg(["--help"]).out).toContain("ctrl-x");
  });

  it("lists local branches with branches", () => {
    const r = xcg(["branches"]);
    expect(r.code).toBe(0);
    expect(r.out.trim().split("\n").sort()).toEqual(
      ["gone-branch", "main", "merged-branch", "unmerged-branch"],
    );
  });

  it("prints the current branch with head-branch", () => {
    expect(xcg(["head-branch"]).out.trim()).toBe("main");
  });

  it("lists remote branches with remote-branches", () => {
    const out = xcg(["remote-branches"]).out;
    expect(out).toContain("remote-only");
    expect(out).not.toContain("HEAD");
  });

  it("falls back to branches when stdout is not a TTY and no args are given", () => {
    const r = Bun.spawnSync(["sh", "-c", `${script} | cat`], {
      cwd: fx.work, stdout: "pipe", stderr: "pipe",
    });
    expect(r.exitCode).toBe(0);
    expect(new TextDecoder().decode(r.stdout)).toContain("main");
  });

  it("exits non-zero for an unknown subcommand", () => {
    expect(xcg(["no-such-subcommand"]).code).not.toBe(0);
  });
});
