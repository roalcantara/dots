#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcPuts = scriptPath("xc-puts");

describe("xc-puts", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given -h or --help", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([xcPuts, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-puts");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([xcPuts, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
      expect(out).toContain("xc-puts");
    });
  });

  describe.skipIf(skipWhenOtherScenario("green"))("when given --green", () => {
    it("prints the message in green", () => {
      const r = Bun.spawnSync([xcPuts, "--green", "Success!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Success!");
    });
  });

  describe.skipIf(skipWhenOtherScenario("red"))("when given --red", () => {
    it("prints the message in red", () => {
      const r = Bun.spawnSync([xcPuts, "--red", "Error!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Error!");
    });
  });

  describe.skipIf(skipWhenOtherScenario("yellow"))("when given --yellow", () => {
    it("prints the message in yellow", () => {
      const r = Bun.spawnSync([xcPuts, "--yellow", "Warning!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Warning!");
    });
  });

  describe.skipIf(skipWhenOtherScenario("prefix"))("when given --prefix", () => {
    it("prints the message with prefix", () => {
      const r = Bun.spawnSync([xcPuts, "--prefix", "SETUP", "Message!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("SETUP");
      expect(out).toContain("Message!");
    });

    it("prints the message with prefix and --warn", () => {
      const r = Bun.spawnSync([xcPuts, "--prefix", "SETUP", "--warn", "Message!"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("SETUP");
      expect(out).toContain("Message!");
    });
  });

  describe.skipIf(skipWhenOtherScenario("no_message"))("when no message is given", () => {
    it("prints usage to stderr and exits 1", () => {
      const r = Bun.spawnSync([xcPuts, "--green"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("Usage:");
    });
  });
});
