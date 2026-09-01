#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("gen");

describe("gen", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("gen");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("gen");
    });

    it("exits with status 1 when toolname argument is missing", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });
});
