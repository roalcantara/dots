#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("keyring");

describe("keyring", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("keyring");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("keyring");
    });

    it("prints subcommand help for get --help", () => {
      const r = Bun.spawnSync([script, "get", "--help"], { stdout: "pipe", stderr: "pipe" });
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("keyring");
    });
  });
});
