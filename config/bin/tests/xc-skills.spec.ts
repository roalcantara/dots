#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import {
  mkdtempSync,
  mkdirSync,
  rmSync,
  symlinkSync,
  writeFileSync,
  chmodSync,
} from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) =>
  selected !== "" && selected !== id;
const script =
  Bun.env.XC_SKILLS ?? join(import.meta.dir, "..", "xc-skills");

const basePath = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

function decode(bytes: Uint8Array): string {
  return new TextDecoder().decode(bytes);
}

/**
 * Create a temp directory pre-populated with symlinks.
 * Each key in `symlinks` becomes a symlink named `key` pointing to `value`.
 */
function makeTmpSourceDir(symlinks: Record<string, string>): string {
  const dir = mkdtempSync(join(tmpdir(), "xc-skills-src-"));
  for (const [name, target] of Object.entries(symlinks)) {
    symlinkSync(target, join(dir, name));
  }
  return dir;
}

/**
 * Create a temp directory (empty, writable).
 */
function makeTmpDir(prefix = "xc-skills-dest-"): string {
  return mkdtempSync(join(tmpdir(), prefix));
}

function run(
  args: string[],
  options: {
    env?: Record<string, string>;
    cwd?: string;
  } = {},
) {
  const env = {
    ...Bun.env,
    PATH: basePath,
    HOME: Bun.env.HOME ?? "/tmp",
    ...options.env,
  };
  const result = Bun.spawnSync([script, ...args], {
    env,
    cwd: options.cwd,
    stdout: "pipe",
    stderr: "pipe",
  });
  return {
    exitCode: result.exitCode,
    stdout: decode(result.stdout),
    stderr: decode(result.stderr),
  };
}

// ── fixtures ──────────────────────────────────────────────────────────────────

const SKILL_TARGETS = {
  "brainstorming.md": "/some/real/path/brainstorming.md",
  "dry-principle.md": "/some/real/path/dry-principle.md",
};

describe("xc-skills", () => {
  // ── help ────────────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("help"))("when help is requested", () => {
    it("prints usage for -h and --help, exits 0", () => {
      for (const flag of ["-h", "--help"]) {
        const r = run([flag]);
        expect(r.exitCode).toBe(0);
        expect(r.stdout).toContain("xc-skills");
        expect(r.stdout).toContain("Usage:");
        expect(r.stderr).toBe("");
      }
    });
  });

  // ── no_args ─────────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("no_args"))("when called with no args", () => {
    it("prints usage and exits 1", () => {
      const r = run([]);
      expect(r.exitCode).toBe(1);
      expect(r.stdout).toContain("Usage:");
    });
  });

  // ── unknown_cmd ─────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("unknown_cmd"))("when an unknown subcommand is given", () => {
    it("exits with error and prints unknown subcommand", () => {
      const r = run(["frobnicate"]);
      expect(r.exitCode).toBe(1);
      expect(r.stderr).toContain("frobnicate");
    });
  });

  // ── sync_no_source ──────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_no_source"))(
    "when sync is called with no source and default does not exist",
    () => {
      it("exits with error mentioning missing source", () => {
        const fakeHome = makeTmpDir("xc-skills-home-");
        try {
          const r = run(["sync"], { env: { HOME: fakeHome } });
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/source|not found/i);
        } finally {
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_missing_source ──────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_missing_source"))(
    "when sync is called with a nonexistent -s path",
    () => {
      it("exits with error mentioning the path", () => {
        const r = run(["sync", "-s", "/nonexistent/path/to/skills"]);
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toContain("/nonexistent/path/to/skills");
      });
    },
  );

  // ── sync_empty_source ────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_empty_source"))(
    "when source directory has no symlinks",
    () => {
      it("warns and exits 1", () => {
        const src = makeTmpDir("xc-skills-empty-");
        // put a regular file (not a symlink) in it
        writeFileSync(join(src, "notasymlink.md"), "content");
        const dest = makeTmpDir();
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/no symlinks/i);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_creates_symlinks ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_creates_symlinks"))(
    "when sync is given a source and target",
    () => {
      it("creates symlinks in the target directory", () => {
        const src = makeTmpSourceDir(SKILL_TARGETS);
        const dest = makeTmpDir();
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("created=2");
          expect(r.stdout).toContain("Synchronization completed successfully");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_dry_run ─────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_dry_run"))(
    "when --dry-run is passed",
    () => {
      it("prints [dry-run] prefixed commands and creates no files", () => {
        const src = makeTmpSourceDir(SKILL_TARGETS);
        const dest = makeTmpDir();
        try {
          const r = run(["sync", "--dry-run", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("[dry-run]");
          // dest should still be empty (no actual symlinks created)
          const entries = Array.from(
            new Bun.Glob("*").scanSync({ cwd: dest, onlyFiles: false }),
          );
          expect(entries.length).toBe(0);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_replaces_changed ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_replaces_changed"))(
    "when a symlink in dest points to a different target",
    () => {
      it("replaces it and reports replaced=1", () => {
        const src = makeTmpSourceDir({ "skill.md": "/new/target.md" });
        const dest = makeTmpDir();
        // pre-seed with wrong target
        symlinkSync("/old/target.md", join(dest, "skill.md"));
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("replaced=1");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_unchanged_skipped ───────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_unchanged_skipped"))(
    "when dest symlink already points to the correct target",
    () => {
      it("skips it and reports unchanged=1", () => {
        const src = makeTmpSourceDir({ "skill.md": "/correct/target.md" });
        const dest = makeTmpDir();
        symlinkSync("/correct/target.md", join(dest, "skill.md"));
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("unchanged=1");
          expect(r.stdout).toContain("created=0");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_skips_non_symlink ───────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_skips_non_symlink"))(
    "when a regular file exists at the dest path",
    () => {
      it("leaves it untouched and warns", () => {
        const src = makeTmpSourceDir({ "skill.md": "/some/target.md" });
        const dest = makeTmpDir();
        // regular file — not a symlink
        writeFileSync(join(dest, "skill.md"), "i am not a symlink");
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("skipped_non_symlink=1");
          expect(r.stderr).toContain("Non-symlink exists");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_prune ───────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_prune"))(
    "when --prune is passed and dest has extra symlinks",
    () => {
      it("removes dest-only symlinks and reports pruned=1", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const dest = makeTmpDir();
        // extra symlink not in source
        symlinkSync("/old.md", join(dest, "orphan.md"));
        try {
          const r = run(["sync", "--prune", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("pruned=1");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_no_prune ────────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_no_prune"))(
    "when --prune is NOT passed and dest has extra symlinks",
    () => {
      it("leaves orphan symlinks alone", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const dest = makeTmpDir();
        symlinkSync("/old.md", join(dest, "orphan.md"));
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("pruned=0");
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_multi_target ────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_multi_target"))(
    "when multiple -t targets are given",
    () => {
      it("syncs to each target independently", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const dest1 = makeTmpDir();
        const dest2 = makeTmpDir();
        try {
          const r = run(["sync", "-s", src, "-t", dest1, "-t", dest2]);
          expect(r.exitCode).toBe(0);
          // two Destination: lines
          const destLines = r.stdout
            .split("\n")
            .filter((l) => l.startsWith("Destination:"));
          expect(destLines.length).toBe(2);
          expect(destLines.some((l) => l.includes(dest1))).toBe(true);
          expect(destLines.some((l) => l.includes(dest2))).toBe(true);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest1, { recursive: true, force: true });
          rmSync(dest2, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_agent_global ────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_agent_global"))(
    "when -a antigravity is given (global, default)",
    () => {
      it("resolves to $HOME/.gemini/antigravity/skills", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const fakeHome = makeTmpDir("xc-skills-home-");
        try {
          const r = run(["sync", "-s", src, "-a", "antigravity"], {
            env: { HOME: fakeHome },
          });
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain(
            join(fakeHome, ".gemini/antigravity/skills"),
          );
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_agent_local ─────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_agent_local"))(
    "when -a antigravity -l is given",
    () => {
      it("resolves to $PWD/.agents/skills", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const cwd = makeTmpDir("xc-skills-cwd-");
        try {
          const r = run(["sync", "-s", src, "-a", "antigravity", "-l"], {
            cwd,
          });
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain(join(cwd, ".agents/skills"));
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(cwd, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_multi_agent ─────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_multi_agent"))(
    "when multiple -a agents are given",
    () => {
      it("syncs to each resolved agent path", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const fakeHome = makeTmpDir("xc-skills-home-");
        try {
          const r = run(
            ["sync", "-s", src, "-a", "antigravity", "-a", "cursor"],
            { env: { HOME: fakeHome } },
          );
          expect(r.exitCode).toBe(0);
          const destLines = r.stdout
            .split("\n")
            .filter((l) => l.startsWith("Destination:"));
          expect(destLines.length).toBe(2);
          expect(
            destLines.some((l) =>
              l.includes(join(fakeHome, ".gemini/antigravity/skills")),
            ),
          ).toBe(true);
          expect(
            destLines.some((l) => l.includes(join(fakeHome, ".cursor/skills"))),
          ).toBe(true);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_agent_and_target ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_agent_and_target"))(
    "when both -a and -t are given",
    () => {
      it("syncs to both the resolved agent path and the explicit target", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const fakeHome = makeTmpDir("xc-skills-home-");
        const extraDest = makeTmpDir();
        try {
          const r = run(
            ["sync", "-s", src, "-a", "antigravity", "-t", extraDest],
            { env: { HOME: fakeHome } },
          );
          expect(r.exitCode).toBe(0);
          const destLines = r.stdout
            .split("\n")
            .filter((l) => l.startsWith("Destination:"));
          expect(destLines.length).toBe(2);
          expect(
            destLines.some((l) =>
              l.includes(join(fakeHome, ".gemini/antigravity/skills")),
            ),
          ).toBe(true);
          expect(destLines.some((l) => l.includes(extraDest))).toBe(true);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
          rmSync(extraDest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_unknown_agent ───────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_unknown_agent"))(
    "when an unknown agent name is given",
    () => {
      it("exits with error mentioning the agent name", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        try {
          const r = run(["sync", "-s", src, "-a", "nonexistent-agent-xyz"]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toContain("nonexistent-agent-xyz");
        } finally {
          rmSync(src, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_source_once ─────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_source_once"))(
    "when --source is given more than once",
    () => {
      it("exits with error about duplicate --source", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        try {
          const r = run(["sync", "-s", src, "-s", src]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/source.*once|once.*source/i);
        } finally {
          rmSync(src, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_local_once ──────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_local_once"))(
    "when --local is given more than once",
    () => {
      it("exits with error about duplicate --local", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const dest = makeTmpDir();
        try {
          const r = run(["sync", "-s", src, "-t", dest, "-l", "-l"]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/local.*once|once.*local/i);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_default_targets ─────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_default_targets"))(
    "when neither -a nor -t is given",
    () => {
      it("uses the default destination list (backward-compat)", () => {
        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const fakeHome = makeTmpDir("xc-skills-home-");
        try {
          const r = run(["sync", "-s", src], { env: { HOME: fakeHome } });
          expect(r.exitCode).toBe(0);
          // All default destinations use $HOME — should see multiple Destination: lines
          const destLines = r.stdout
            .split("\n")
            .filter((l) => l.startsWith("Destination:"));
          expect(destLines.length).toBeGreaterThan(1);
          // At least one should contain antigravity (from default list)
          expect(
            destLines.some((l) =>
              l.includes(join(fakeHome, ".gemini/antigravity/skills")),
            ),
          ).toBe(true);
        } finally {
          rmSync(src, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── sync_dest_not_writable ───────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("sync_dest_not_writable"))(
    "when the destination directory is not writable",
    () => {
      it("warns and skips that destination", () => {
        // Only meaningful when not running as root
        if (process.getuid?.() === 0) return;

        const src = makeTmpSourceDir({ "skill.md": "/target.md" });
        const dest = makeTmpDir();
        chmodSync(dest, 0o555); // read + execute, no write
        try {
          const r = run(["sync", "-s", src, "-t", dest]);
          // exits 0 (overall not a fatal error) but warns
          expect(r.stderr).toMatch(/not writable|skipping/i);
        } finally {
          chmodSync(dest, 0o755);
          rmSync(src, { recursive: true, force: true });
          rmSync(dest, { recursive: true, force: true });
        }
      });
    },
  );
  // ── collect_no_source ──────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_no_source"))(
    "collect: when source dir does not exist",
    () => {
      it("creates source dir and completes", () => {
        const src = makeTmpSourceDir({ "skill.md": "/some/target.md" });
        const fakeHome = makeTmpDir("xc-skills-home-");
        // Build an agent dir with a real file in the resolved global path
        const agentDir = join(fakeHome, ".gemini/antigravity/skills");
        mkdirSync(agentDir, { recursive: true });
        writeFileSync(join(agentDir, "new-skill.md"), "content");
        const customSrc = join(fakeHome, "new-source");
        try {
          const r = run(["collect", "-s", customSrc, "-a", "antigravity"], {
            env: { HOME: fakeHome },
          });
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("copied=1");
        } finally {
          rmSync(fakeHome, { recursive: true, force: true });
          rmSync(src, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_copies_file ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_copies_file"))(
    "collect: when agent dir has a regular file",
    () => {
      it("copies to source and replaces with symlink", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const agentDir = makeTmpDir("xc-skills-agent-");
        writeFileSync(join(agentDir, "skill.md"), "my skill");
        try {
          const r = run(["collect", "-s", srcDir, "-t", agentDir]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("copied=1");
          expect(r.stdout).toContain("linked=0");
          // source now has the file
          expect(Bun.file(join(srcDir, "skill.md")).size).toBeGreaterThan(0);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(agentDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_conflict_links ─────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_conflict_links"))(
    "collect: when file already exists in source",
    () => {
      it("skips copy but still creates symlink in agent dir", async () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        writeFileSync(join(srcDir, "skill.md"), "source version");
        const agentDir = makeTmpDir("xc-skills-agent-");
        writeFileSync(join(agentDir, "skill.md"), "agent version");
        try {
          const r = run(["collect", "-s", srcDir, "-t", agentDir]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("linked=1");
          expect(r.stdout).toContain("copied=0");
          expect(r.stderr).toMatch(/conflict|already exists|skipping copy/i);
          // source retains original
          expect(await Bun.file(join(srcDir, "skill.md")).text()).toBe("source version");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(agentDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_skips_symlink ──────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_skips_symlink"))(
    "collect: when entry in agent dir is already a symlink",
    () => {
      it("skips it entirely", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const agentDir = makeTmpDir("xc-skills-agent-");
        symlinkSync("/some/path.md", join(agentDir, "skill.md"));
        try {
          const r = run(["collect", "-s", srcDir, "-t", agentDir]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("skipped_symlink=1");
          expect(r.stdout).toContain("copied=0");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(agentDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_skips_missing_dir ──────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_skips_missing_dir"))(
    "collect: when an agent directory does not exist",
    () => {
      it("silently skips it", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const fakeHome = makeTmpDir("xc-skills-home-");
        // antigravity global dir does NOT exist under fakeHome
        try {
          const r = run(["collect", "-s", srcDir, "-a", "antigravity"], {
            env: { HOME: fakeHome },
          });
          expect(r.exitCode).toBe(0);
          expect(r.stderr).toBe("");
          // no "Agent:" lines since dir was skipped
          expect(r.stdout).not.toContain("Agent:");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_dry_run ────────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_dry_run"))(
    "collect: when --dry-run is passed",
    () => {
      it("prints actions and makes no filesystem changes", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const agentDir = makeTmpDir("xc-skills-agent-");
        writeFileSync(join(agentDir, "skill.md"), "content");
        try {
          const r = run(["collect", "--dry-run", "-s", srcDir, "-t", agentDir]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain("[dry-run]");
          // agent dir still has regular file (not replaced)
          const entries = Array.from(
            new Bun.Glob("*").scanSync({ cwd: srcDir, onlyFiles: false }),
          );
          expect(entries.length).toBe(0);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(agentDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_agent_global ───────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_agent_global"))(
    "collect: when -a antigravity is given (global)",
    () => {
      it("inspects $HOME/.gemini/antigravity/skills", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const fakeHome = makeTmpDir("xc-skills-home-");
        const agentDir = join(fakeHome, ".gemini/antigravity/skills");
        mkdirSync(agentDir, { recursive: true });
        writeFileSync(join(agentDir, "skill.md"), "content");
        try {
          const r = run(["collect", "-s", srcDir, "-a", "antigravity"], {
            env: { HOME: fakeHome },
          });
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain(agentDir);
          expect(r.stdout).toContain("copied=1");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_agent_local ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_agent_local"))(
    "collect: when -a antigravity -l is given",
    () => {
      it("inspects $PWD/.agents/skills", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const cwd = makeTmpDir("xc-skills-cwd-");
        const agentDir = join(cwd, ".agents/skills");
        mkdirSync(agentDir, { recursive: true });
        writeFileSync(join(agentDir, "skill.md"), "content");
        try {
          const r = run(["collect", "-s", srcDir, "-a", "antigravity", "-l"], { cwd });
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain(agentDir);
          expect(r.stdout).toContain("copied=1");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(cwd, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_multi_agent ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_multi_agent"))(
    "collect: when multiple -a agents are given",
    () => {
      it("inspects each resolved agent dir", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const fakeHome = makeTmpDir("xc-skills-home-");
        for (const rel of [".gemini/antigravity/skills", ".cursor/skills"]) {
          const d = join(fakeHome, rel);
          mkdirSync(d, { recursive: true });
          writeFileSync(join(d, `${rel.split("/")[1]}-skill.md`), "content");
        }
        try {
          const r = run(
            ["collect", "-s", srcDir, "-a", "antigravity", "-a", "cursor"],
            { env: { HOME: fakeHome } },
          );
          expect(r.exitCode).toBe(0);
          const agentLines = r.stdout.split("\n").filter((l) => l.startsWith("Agent:"));
          expect(agentLines.length).toBe(2);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_explicit_target ────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_explicit_target"))(
    "collect: when -t is given",
    () => {
      it("inspects that explicit directory", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const targetDir = makeTmpDir("xc-skills-target-");
        writeFileSync(join(targetDir, "skill.md"), "content");
        try {
          const r = run(["collect", "-s", srcDir, "-t", targetDir]);
          expect(r.exitCode).toBe(0);
          expect(r.stdout).toContain(targetDir);
          expect(r.stdout).toContain("copied=1");
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(targetDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_all_agents ─────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_all_agents"))(
    "collect: when no -a or -t is given",
    () => {
      it("inspects all known agent dirs, skipping absent ones", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const fakeHome = makeTmpDir("xc-skills-home-");
        // Create just one agent dir
        const agentDir = join(fakeHome, ".gemini/antigravity/skills");
        mkdirSync(agentDir, { recursive: true });
        writeFileSync(join(agentDir, "skill.md"), "content");
        try {
          const r = run(["collect", "-s", srcDir], { env: { HOME: fakeHome } });
          expect(r.exitCode).toBe(0);
          // At least one Agent: line for antigravity
          expect(r.stdout).toContain(agentDir);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(fakeHome, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_source_once ────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_source_once"))(
    "collect: when --source is given more than once",
    () => {
      it("exits with error", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        try {
          const r = run(["collect", "-s", srcDir, "-s", srcDir]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/source.*once|once.*source/i);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_local_once ─────────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_local_once"))(
    "collect: when --local is given more than once",
    () => {
      it("exits with error", () => {
        const srcDir = makeTmpDir("xc-skills-src-");
        const targetDir = makeTmpDir("xc-skills-target-");
        try {
          const r = run(["collect", "-s", srcDir, "-t", targetDir, "-l", "-l"]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/local.*once|once.*local/i);
        } finally {
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(targetDir, { recursive: true, force: true });
        }
      });
    },
  );

  // ── collect_unknown_agent ──────────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_unknown_agent"))(
    "collect: when an unknown agent is given",
    () => {
      it("exits with error mentioning the agent name", () => {
        const r = run(["collect", "-a", "no-such-agent-xyz"]);
        expect(r.exitCode).toBe(1);
        expect(r.stderr).toContain("no-such-agent-xyz");
      });
    },
  );

  // ── collect_source_not_writable ────────────────────────────────────────────

  describe.skipIf(skipWhenOtherScenario("collect_source_not_writable"))(
    "collect: when the source directory is not writable",
    () => {
      it("exits with error", () => {
        if (process.getuid?.() === 0) return;
        const srcDir = makeTmpDir("xc-skills-src-");
        const agentDir = makeTmpDir("xc-skills-agent-");
        writeFileSync(join(agentDir, "skill.md"), "content");
        chmodSync(srcDir, 0o555);
        try {
          const r = run(["collect", "-s", srcDir, "-t", agentDir]);
          expect(r.exitCode).toBe(1);
          expect(r.stderr).toMatch(/not writable|cannot write/i);
        } finally {
          chmodSync(srcDir, 0o755);
          rmSync(srcDir, { recursive: true, force: true });
          rmSync(agentDir, { recursive: true, force: true });
        }
      });
    },
  );
});
