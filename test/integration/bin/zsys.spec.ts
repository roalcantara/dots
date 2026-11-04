#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("zsys");

describe("zsys", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("zsys");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("zsys");
    });

    it("exits with status 1 when subcommand is missing", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });

  describe("cmd subcommand", () => {
    it("checks command existence with --exists", () => {
      const r = Bun.spawnSync([script, "cmd", "--exists", "ls"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });

    it("returns command path with --path", () => {
      const r = Bun.spawnSync([script, "cmd", "--path", "ls"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("ls");
    });
  });
});
