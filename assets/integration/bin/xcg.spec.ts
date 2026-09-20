#!/usr/bin/env bun
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { type GitFixture, makeGitFixture } from "./support/git-fixture";

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
