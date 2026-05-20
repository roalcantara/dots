#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcPuts = scriptPath("xc-puts");

describe("xc-puts", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given -h or --help", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync(["zsh", xcPuts, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage");
      expect(out).toContain("xc-puts");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync(["zsh", xcPuts, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("green"))("when given --green", () => {
    it("prints the message in green", () => {
      const r = Bun.spawnSync(["zsh", xcPuts, "--green", "test green"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("test green");
    });
  });

  describe.skipIf(skipWhenOtherScenario("no_message"))("when no message is given", () => {
    it("prints usage to stderr and exits 1", () => {
      const r = Bun.spawnSync(["zsh", xcPuts, "--green"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("Usage");
    });
  });
});
