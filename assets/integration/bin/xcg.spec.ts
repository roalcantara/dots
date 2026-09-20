#!/usr/bin/env bun
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { join } from "node:path";
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

interface Row { kind: string; ref: string; display: string }

function rows(view: string): Row[] {
  const r = xcg(["__list", view]);
  expect(r.code).toBe(0);
  return r.out.trim().split("\n").filter(Boolean).map((line) => {
    const [kind, ref, display] = line.split("\t");
    return { kind, ref, display };
  });
}

describe("xcg __list", () => {
  it("lists every local branch in the local view", () => {
    expect(rows("local").map((r) => r.ref).sort()).toEqual(
      ["gone-branch", "main", "merged-branch", "unmerged-branch"],
    );
  });

  it("tags local rows with kind local", () => {
    expect(rows("local").every((r) => r.kind === "local")).toBe(true);
  });

  it("excludes origin/HEAD from the remote view", () => {
    const refs = rows("remote").map((r) => r.ref);
    expect(refs).toContain("origin/remote-only");
    expect(refs).toContain("origin/main");
    expect(refs).not.toContain("origin");
  });

  it("tags remote rows with kind remote", () => {
    expect(rows("remote").every((r) => r.kind === "remote")).toBe(true);
  });

  it("excludes protected branches from the merged view", () => {
    expect(rows("merged").map((r) => r.ref)).toEqual(["merged-branch"]);
  });

  it("lists only gone branches in the gone view", () => {
    expect(rows("gone").map((r) => r.ref)).toEqual(["gone-branch"]);
  });

  it("puts the branch name in the display field", () => {
    const row = rows("local").find((r) => r.ref === "main");
    expect(row?.display).toContain("main");
  });

  it("defaults to the local view when no view is given", () => {
    const r = xcg(["__list"]);
    expect(r.code).toBe(0);
    expect(r.out).toContain("merged-branch");
  });

  it("remembers the last view in XCG_STATE", () => {
    const stateFile = join(fx.root, "state");
    const env = { ...Bun.env, XCG_STATE: stateFile };
    Bun.spawnSync([script, "__list", "gone"], { cwd: fx.work, env, stdout: "pipe", stderr: "pipe" });
    const r = Bun.spawnSync([script, "__list"], { cwd: fx.work, env, stdout: "pipe", stderr: "pipe" });
    const out = new TextDecoder().decode(r.stdout);
    expect(out).toContain("gone-branch");
    expect(out).not.toContain("unmerged-branch");
  });
});

describe("xcg __protected", () => {
  it("includes the default branch and HEAD", () => {
    const out = xcg(["__protected"]).out.trim().split("\n");
    expect(out).toContain("main");
  });
});

function row(cwd: string, view: string, ref: string): string {
  const r = Bun.spawnSync([script, "__list", view], { cwd, stdout: "pipe", stderr: "pipe" });
  const line = new TextDecoder().decode(r.stdout).split("\n").find((l) => l.split("\t")[1] === ref);
  if (!line) throw new Error(`no ${ref} row in ${view} view`);
  return line;
}

function localBranches(cwd: string): string[] {
  const r = Bun.spawnSync(["git", "branch", "--format=%(refname:short)"], {
    cwd, stdout: "pipe", stderr: "pipe",
  });
  return new TextDecoder().decode(r.stdout).trim().split("\n").filter(Boolean);
}

describe("xcg __delete", () => {
  it("deletes a merged branch under XCG_YES", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "merged", "merged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(localBranches(f.work)).not.toContain("merged-branch");
    } finally { f.cleanup(); }
  });

  it("refuses an unmerged branch in safe mode and keeps it", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "local", "unmerged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).not.toBe(0);
      expect(localBranches(f.work)).toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("deletes an unmerged branch in force mode", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "force", row(f.work, "local", "unmerged-branch")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(localBranches(f.work)).not.toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("refuses a protected branch and names it", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "force", row(f.work, "local", "main")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      const combined = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(combined).toContain("main");
      expect(localBranches(f.work)).toContain("main");
    } finally { f.cleanup(); }
  });

  it("deletes several branches in one call", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([
        script, "__delete", "force",
        row(f.work, "local", "merged-branch"),
        row(f.work, "local", "unmerged-branch"),
      ], { cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const left = localBranches(f.work);
      expect(left).not.toContain("merged-branch");
      expect(left).not.toContain("unmerged-branch");
    } finally { f.cleanup(); }
  });

  it("deletes a remote branch under XCG_YES", () => {
    const f = makeGitFixture();
    try {
      const r = Bun.spawnSync([script, "__delete", "safe", row(f.work, "remote", "origin/remote-only")], {
        cwd: f.work, env: { ...Bun.env, XCG_YES: "1" }, stdout: "pipe", stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const refs = Bun.spawnSync(["git", "ls-remote", "--heads", "origin"], {
        cwd: f.work, stdout: "pipe", stderr: "pipe",
      });
      expect(new TextDecoder().decode(refs.stdout)).not.toContain("remote-only");
    } finally { f.cleanup(); }
  });
});
