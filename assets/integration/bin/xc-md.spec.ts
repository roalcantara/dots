#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcMd = scriptPath("xc-md");

describe("xc-md", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given -h or --help", () => {
    it("prints usage with -h and exits 0", () => {
      const r = Bun.spawnSync([xcMd, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage");
      expect(out).toContain("xc-md");
    });

    it("prints usage with --help and exits 0", () => {
      const r = Bun.spawnSync([xcMd, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("stdin"))("when given markdown on stdin", () => {
    it("renders piped markdown and exits 0", () => {
      const r = Bun.spawnSync([xcMd], {
        stdin: new TextEncoder().encode("# Title\n\nHello, world!\n"),
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out.length).toBeGreaterThan(0);
    });
  });
});
