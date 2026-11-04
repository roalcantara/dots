#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { binRoot, fixturesDir, realUsageBin, realUsageDir, scriptPath } from "./support/paths";

const toolBin = realUsageDir();

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;

const xc = scriptPath("xc");
const fixtureBin = join(fixturesDir, "xc-launcher", "bin");

const testEnv = (extra: Record<string, string | undefined> = {}) => ({
  ...process.env,
  PATH: `${binRoot}:${toolBin}:/usr/bin:/bin`,
  ...extra,
});

describe("xc launcher", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("self help", () => {
    it("prints ##? help with -h and exits 0", () => {
      const r = Bun.spawnSync([xc, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: binRoot }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc");
      expect(out).toContain("list");
      expect(out).toContain("launcher");
    });
  });

  describe.skipIf(skipWhenOtherScenario("list"))("list", () => {
    it("discovers xc-fabric and xc-sample in fixture dir", () => {
      const r = Bun.spawnSync([xc, "list"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: fixtureBin }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-sample");
      expect(out).toContain("Fixture tool");
    });

    it("lists real tools from config/bin when XC_BIN_DIR unset", () => {
      const r = Bun.spawnSync([xc, "list"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: binRoot }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-fabric");
      expect(out).toContain("xc-git");
      expect(out).not.toMatch(/\bxc\s+Interactive launcher/);
    });
  });

  describe.skipIf(skipWhenOtherScenario("no_fzf"))("without fzf", () => {
    it("exits 1 with install hint when interactive and fzf missing", () => {
      const usageOnly = mkdtempSync(join(tmpdir(), "xc-no-fzf-"));
      symlinkSync(realUsageBin(), join(usageOnly, "usage"));
      try {
        const r = Bun.spawnSync([xc], {
          stdout: "pipe",
          stderr: "pipe",
          env: testEnv({ XC_BIN_DIR: fixtureBin, PATH: `${usageOnly}:/usr/bin:/bin` }),
        });
        expect(r.exitCode).toBe(1);
        const err = new TextDecoder().decode(r.stderr);
        expect(err).toMatch(/fzf|gum/i);
      } finally {
        rmSync(usageOnly, { recursive: true, force: true });
      }
    });
  });

  describe.skipIf(skipWhenOtherScenario("discover_skip_self"))("discovery", () => {
    it("does not list the launcher itself as a tool", () => {
      const r = Bun.spawnSync([xc, "list"], {
        stdout: "pipe",
        stderr: "pipe",
        env: testEnv({ XC_BIN_DIR: binRoot }),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      const lines = out.split("\n").filter((l) => l.startsWith("xc "));
      expect(lines.length).toBe(0);
    });
  });
});
