#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const script =
  Bun.env.XC_GIT_LOG_FZF ?? join(import.meta.dir, "..", "xc-git-log-fzf");

describe("xc-git-log-fzf", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("when given --help", () => {
    it("prints usage to stdout", () => {
      const r = Bun.spawnSync(["zsh", script, "--help"], { stdout: "pipe", stderr: "pipe" });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Interactive git log");
      expect(out).toContain("Usage:");
    });
  });

  describe.skipIf(skipWhenOtherScenario("missing_gitx"))("when gitx is missing", () => {
    it("exits with code 127", () => {
      const xdg = mkdtempSync(join(tmpdir(), "xc-git-log-fzf-spec-"));
      try {
        const r = Bun.spawnSync(["zsh", script], {
          env: { ...Bun.env, XDG_CONFIG_HOME: xdg, HOME: xdg },
          stdout: "pipe",
          stderr: "pipe",
        });
        expect(r.exitCode).toBe(127);
        expect(new TextDecoder().decode(r.stderr)).toContain("gitx");
      } finally {
        rmSync(xdg, { recursive: true, force: true });
      }
    });
  });
});
