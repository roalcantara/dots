#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("yw");

describe("yw", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("yw");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("yw");
    });
  });

  describe("dry run execution", () => {
    it("prints command in dry-run mode when package and script are provided", () => {
      const r = Bun.spawnSync([script, "web", "build", "--dry-run"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("yarn workspace web build");
    });
  });
});
