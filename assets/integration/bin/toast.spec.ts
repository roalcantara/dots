#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const script = scriptPath("toast");

describe("toast", () => {
  describe("help and argument validation", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("toast");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("toast");
    });

    it("exits with status 1 when message is missing", () => {
      const r = Bun.spawnSync([script], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(1);
    });
  });

  describe("toast notifications", () => {
    it("executes toast with message positional", () => {
      const r = Bun.spawnSync([script, "Hello, world!"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });

    it("executes toast with message, duration, and type positionals", () => {
      const r = Bun.spawnSync([script, "Success toast", "1", "success"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });

    it("executes toast with flags -d and -t", () => {
      const r = Bun.spawnSync([script, "Error toast", "-d", "1", "-t", "error"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
    });
  });
});
