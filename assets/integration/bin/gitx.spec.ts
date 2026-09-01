#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("gitx");

describe("gitx", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("gitx");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("gitx");
    });
  });

  describe("git subcommands", () => {
    it("prints current branch with head-branch", () => {
      const r = Bun.spawnSync([script, "head-branch"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });

    it("prints branches list with branches", () => {
      const r = Bun.spawnSync([script, "branches"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });
  });
});
