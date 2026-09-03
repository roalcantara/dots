#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, unlinkSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { repoRoot, scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const script = scriptPath("xc-git");

describe("xc-git", () => {
  describe.skipIf(skipWhenOtherScenario("help"))("help and dispatch", () => {
    it("prints top-level usage with -h and exits 0", () => {
      const r = Bun.spawnSync([script, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-git");
      expect(out).toContain("branch-preview");
      expect(out).toContain("fixup-suggest");
      expect(out).toContain("log-fzf");
    });

    it("prints top-level usage with no args and exits 1", () => {
      const r = Bun.spawnSync([script], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("branch-preview");
    });

    it("prints error for unknown subcommand and exits 1", () => {
      const r = Bun.spawnSync([script, "nonexistent"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("nonexistent");
    });
  });

  describe.skipIf(skipWhenOtherScenario("branch_preview_help"))("branch-preview subcommand", () => {
    it("prints subcommand help with -h and exits 1", () => {
      const r = Bun.spawnSync([script, "branch-preview", "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("branch");
      expect(out).toContain("branch-preview");
    });

    it("exits 1 with missing branch arg", () => {
      const r = Bun.spawnSync([script, "branch-preview"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("branch");
    });

    it("prints branch info without gum on PATH (plain headings)", () => {
      const pathWithoutGum = (Bun.env.PATH ?? "")
        .split(":")
        .filter((p) => !p.includes("gum"))
        .join(":");
      const r = Bun.spawnSync(
        [script, "branch-preview", "HEAD"],
        {
          cwd: repoRoot,
          env: { ...Bun.env, PATH: pathWithoutGum },
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("── Last commit ──");
      expect(out).not.toContain("gum style");
    });
  });

  describe.skipIf(skipWhenOtherScenario("fixup_suggest"))("fixup-suggest subcommand", () => {
    it("prints subcommand help with --help and exits 1", () => {
      const r = Bun.spawnSync([script, "fixup-suggest", "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("fixup-suggest");
      expect(out).toContain("--best");
      expect(out).toContain("--dry-run");
    });

    it("suggests latest branch touch for paths with history", () => {
      const r = Bun.spawnSync(
        [script, "fixup-suggest", "--dry-run", "config/bin/README.md"],
        {
          cwd: repoRoot,
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Target paths (arguments)");
      expect(out).toMatch(/→ fixup [0-9a-f]+\s+.+/);
      expect(out).toContain("latest branch commit");
      expect(out).not.toContain("via related root file");
    });

    it("exits 1 with -q when no fixup target exists", () => {
      const orphan = join(repoRoot, ".xc-git-spec-orphan");
      writeFileSync(orphan, "spec orphan\n");
      try {
        const r = Bun.spawnSync(
          [script, "fixup-suggest", "-q", ".xc-git-spec-orphan"],
          {
            cwd: repoRoot,
            stdout: "pipe",
            stderr: "pipe",
          },
        );
        expect(r.exitCode).toBe(1);
        expect(new TextDecoder().decode(r.stderr)).toContain(
          "run without -q",
        );
      } finally {
        unlinkSync(orphan);
      }
    });

    it("prints best hash with -q for a path with branch history", () => {
      const r = Bun.spawnSync(
        [script, "fixup-suggest", "-q", "config/bin/README.md"],
        {
          cwd: repoRoot,
          stdout: "pipe",
          stderr: "pipe",
        },
      );
      expect(r.exitCode).toBe(0);
      const hash = new TextDecoder().decode(r.stdout).trim();
      expect(hash).toMatch(/^[0-9a-f]{7,40}$/);
    });

    it("exits 1 when not inside a git repository", () => {
      const r = Bun.spawnSync([script, "fixup-suggest"], {
        cwd: "/tmp",
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("git repository");
    });
  });

  describe.skipIf(skipWhenOtherScenario("log_fzf"))("log-fzf subcommand", () => {
    it("prints subcommand help with -h and exits 1", () => {
      const r = Bun.spawnSync([script, "log-fzf", "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(1);
      const out = new TextDecoder().decode(r.stdout) + new TextDecoder().decode(r.stderr);
      expect(out).toContain("log-fzf");
    });

    it("exits 127 when gitx is missing", () => {
      const xdg = mkdtempSync(join(tmpdir(), "xc-git-spec-"));
      try {
        const r = Bun.spawnSync([script, "log-fzf"], {
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
