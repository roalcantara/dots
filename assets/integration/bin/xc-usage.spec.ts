#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { join } from "node:path";
import { fixturesDir, scriptPath } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcUsage = scriptPath("xc-usage");
const fixtures = join(fixturesDir, "xc-usage");

describe("xc-usage", () => {
  describe.skipIf(skipWhenOtherScenario("self_help"))("self help", () => {
    it("prints ##? help with -h and exits 0", () => {
      const r = Bun.spawnSync(["zsh", xcUsage, "-h"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-usage");
      expect(out).toContain("guard");
      expect(out).toContain("print");
      expect(out).toContain("validate");
      expect(out).toContain("list-subs");
      expect(out).toContain("preview");
      expect(out).toContain("--scope");
    });

    it("prints help with no args and exits 0", () => {
      const r = Bun.spawnSync(["zsh", xcUsage], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("xc-usage");
    });

    it("exits 0 with --help", () => {
      const r = Bun.spawnSync(["zsh", xcUsage, "--help"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("guard_help"))("guard when given help flag", () => {
    it("prints ##? and exits 0", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "guard", join(fixtures, "with-docopt.zsh"), "-h"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("fixture-with-docopt");
      expect(out).toContain("Usage:");
      expect(out).toContain("-h, --help");
    });

    it("works with --help too", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "guard", join(fixtures, "with-docopt.zsh"), "--help"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("guard_continue"))("guard when not help", () => {
    it("exits 2 without printing", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "guard", join(fixtures, "with-docopt.zsh"), "arg1"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(2);
      expect(new TextDecoder().decode(r.stdout)).toBe("");
    });
  });

  describe.skipIf(skipWhenOtherScenario("missing_docopt"))("missing ##? header", () => {
    it("exits 1 and references docopt", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "guard", join(fixtures, "legacy-hash.zsh"), "-h"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("##?");
      expect(err).toContain("docopt.org");
    });

    it("print on legacy file exits 1", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", join(fixtures, "legacy-hash.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
    });

    it("guard on missing file exits 1", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "guard", "/nonexistent-file", "-h"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("not found");
    });
  });

  describe.skipIf(skipWhenOtherScenario("print"))("print subcommand", () => {
    it("emits ##? lines and exits 0", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", join(fixtures, "with-docopt.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("fixture-with-docopt");
      expect(out).toContain("Usage:");
    });
  });

  describe.skipIf(skipWhenOtherScenario("validate_ok"))("validate success", () => {
    it("exits 0 for valid ##? header", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "validate", join(fixtures, "with-docopt.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
    });
  });

  describe.skipIf(skipWhenOtherScenario("validate_fail"))("validate failure", () => {
    it("exits 1 when -h not documented", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "validate", join(fixtures, "missing-help-flag.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("not documented");
    });

    it("exits 1 for legacy #? files", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "validate", join(fixtures, "legacy-hash.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
    });
  });

  describe.skipIf(skipWhenOtherScenario("footer"))("print footer", () => {
    it("appends help footer when missing from ##?", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", join(fixtures, "missing-help-flag.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("-h, --help");
    });

    it("skips footer with --no-help-footer", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", "--no-help-footer", join(fixtures, "missing-help-flag.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).not.toContain("-h, --help");
    });
  });

  describe.skipIf(skipWhenOtherScenario("scope_main"))("scoped print --scope main", () => {
    const dispatcher = join(fixtures, "dispatcher-docopt.zsh");

    it("prints main block only", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", dispatcher, "--scope", "main"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Subcommands:");
      expect(out).toContain("xc-alpha");
      expect(out).not.toContain("xc-alpha ping -");
      expect(out).not.toContain("xc-alpha pong -");
    });
  });

  describe.skipIf(skipWhenOtherScenario("scope_sub"))("scoped print --scope sub", () => {
    const dispatcher = join(fixtures, "dispatcher-docopt.zsh");

    it("prints ping sub block", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", dispatcher, "--scope", "sub:ping"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-alpha ping");
      expect(out).toContain("xc-alpha ping -h");
    });

    it("prints pong sub block", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", dispatcher, "--scope", "sub:pong"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("xc-alpha pong");
    });
  });

  describe.skipIf(skipWhenOtherScenario("scope_sub_missing"))("scoped print unknown sub", () => {
    it("exits 1 for missing sub scope", () => {
      const r = Bun.spawnSync(
        [
          "zsh",
          xcUsage,
          "print",
          join(fixtures, "dispatcher-docopt.zsh"),
          "--scope",
          "sub:missing",
        ],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("unknown subcommand scope");
    });
  });

  describe.skipIf(skipWhenOtherScenario("list_subs"))("list-subs", () => {
    it("prints subcommand names one per line", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "list-subs", join(fixtures, "dispatcher-docopt.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const lines = new TextDecoder()
        .decode(r.stdout)
        .trim()
        .split("\n")
        .filter(Boolean);
      expect(lines).toEqual(["ping", "pong"]);
    });
  });

  describe.skipIf(skipWhenOtherScenario("preview_stacked"))("preview stacked help", () => {
    it("prints main and sub section headers", () => {
      const r = Bun.spawnSync(
        [
          "zsh",
          xcUsage,
          "preview",
          join(fixtures, "dispatcher-docopt.zsh"),
          "--tool",
          "xc-alpha",
        ],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-alpha - Main command:");
      expect(out).toContain("xc-alpha ping - Subcommand:");
      expect(out).toContain("xc-alpha pong - Subcommand:");
      expect(out).toContain("Subcommands:");
      expect(out).toContain("xc-alpha ping -h");
    });
  });

  describe.skipIf(skipWhenOtherScenario("metadata"))("dual #? + ##? headers", () => {
    it("validate succeeds when both #? and ##? exist", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "validate", join(fixtures, "with-metadata.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
    });

    it("print --metadata emits only #? lines", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", "--metadata", join(fixtures, "with-metadata.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("License RIT");
      expect(out).not.toContain("##?");
      expect(out).not.toContain("Usage:");
    });

    it("print does NOT include #? metadata in default output", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "print", "--no-help-footer", join(fixtures, "with-metadata.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).not.toContain("License RIT");
      expect(out).toContain("Usage:");
    });
  });
});
