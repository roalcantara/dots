#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcToast = scriptPath("xc-toast");

describe("xc-toast", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given -h or --help", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-toast");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-toast");
    });
  });

  describe.skipIf(skipWhenOtherScenario("invocation"))("when invoked with valid arguments", () => {
    it("displays toast with positional message and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "Hello, world!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });

    it("displays toast with message and duration and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "Hello, world!", "1"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });

    it("displays toast with message, duration, and type and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "Hello, world!", "1", "error"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });

    it("displays toast with flags and exits 0", () => {
      const r = Bun.spawnSync([xcToast, "Process started", "-d", "1", "-t", "info"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("no_message"))("when no message is given", () => {
    it("prints usage to stderr and exits 1", () => {
      const r = Bun.spawnSync([xcToast], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("Usage:");
    });
  });
});
