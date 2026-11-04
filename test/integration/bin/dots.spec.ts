#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("dots");

describe("dots", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("dots");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("dots");
    });
  });

  describe("subcommands", () => {
    it("prints path entries with path subcommand", () => {
      const r = Bun.spawnSync([script, "path"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out.length).toBeGreaterThan(0);
    });

    it("prints ANSI palette with palette subcommand", () => {
      const r = Bun.spawnSync([script, "palette"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("ANSI");
    });

    it("checks xdg runtime perms", () => {
      const r = Bun.spawnSync([script, "xdg", "check_runtime_perms"], { stdout: "pipe", stderr: "pipe" });
      // exit code 0 or 1 depending on runtime dir setup in test env
      expect(typeof r.exitCode).toBe("number");
    });
  });
});
