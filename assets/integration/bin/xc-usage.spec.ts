#!/usr/bin/env bun

import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { fixturesDir, repoRoot, scriptPath, zshFunctionsDir } from "./support/paths";

const selected = (Bun.env.usage_scenario ?? "").trim();
const skipWhenOtherScenario = (id: string) => selected !== "" && selected !== id;
const xcUsage = scriptPath("xc-usage");
const xcMd = scriptPath("xc-md");
const fixtures = join(fixturesDir, "xc-usage");

function docoptHelpLines(path: string): string {
  return readFileSync(path, "utf8")
    .split("\n")
    .filter((line) => line.startsWith("##?"))
    .map((line) => line.replace(/^##?\s?/, ""))
    .join("\n");
}

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
      expect(out).toContain("--md");
      expect(out).toContain("--scope");
      expect(out).toContain("--preview");
      expect(out).not.toContain("--validate");
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

  describe.skipIf(skipWhenOtherScenario("target_first"))("target-first resolution", () => {
    it("resolves a PATH executable and prints its ##? header", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "with-docopt.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("fixture-with-docopt");
      expect(out).toContain("Usage:");
      expect(out).toContain("-h, --help");
    });

    it("resolves a Zsh function name when FPATH is set", () => {
      const r = Bun.spawnSync(["zsh", xcUsage, "dummy-func"], {
        stdout: "pipe",
        stderr: "pipe",
        env: { ...process.env, FPATH: fixtures },
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("dummy-func");
      expect(out).toContain("dummy-func [options]");
    });

    it("exits 1 for unresolvable target", () => {
      const r = Bun.spawnSync(["zsh", xcUsage, "no-such-function-xyz"], {
        stdout: "pipe",
        stderr: "pipe",
        env: { ...process.env, FPATH: zshFunctionsDir },
      });
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("could not resolve help");
    });
  });

  describe.skipIf(skipWhenOtherScenario("missing_docopt"))("missing ##? header", () => {
    it("exits 1 and references docopt for legacy #? file", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "legacy-hash.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      const err = new TextDecoder().decode(r.stderr);
      expect(err).toContain("##?");
      expect(err).toContain("docopt.org");
    });

    it("exits 1 for non-existent file", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, "/nonexistent-file"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(1);
      expect(new TextDecoder().decode(r.stderr)).toContain("could not resolve help");
    });
  });

  describe.skipIf(skipWhenOtherScenario("docopt_lint"))("##? header lint (integration)", () => {
    it("valid fixture documents Usage and -h", () => {
      const help = docoptHelpLines(join(fixtures, "with-docopt.zsh"));
      expect(help).toContain("Usage:");
      expect(help).toMatch(/-h|--help/);
    });

    it("missing-help-flag fixture lacks -h in ##? (emit still prints body)", () => {
      const help = docoptHelpLines(join(fixtures, "missing-help-flag.zsh"));
      expect(help).toContain("Usage:");
      expect(help).not.toMatch(/-h|--help/);
    });
  });

  describe.skipIf(skipWhenOtherScenario("scope_main"))("scoped --scope main", () => {
    const dispatcher = join(fixtures, "dispatcher-docopt.zsh");

    it("prints main block only", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, dispatcher, "--scope", "main"],
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

  describe.skipIf(skipWhenOtherScenario("scope_sub"))("scoped --scope sub", () => {
    const dispatcher = join(fixtures, "dispatcher-docopt.zsh");

    it("prints ping sub block", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, dispatcher, "--scope", "sub:ping"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("xc-alpha ping");
      expect(out).toContain("xc-alpha ping -h");
    });

    it("prints pong sub block", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, dispatcher, "--scope", "sub:pong"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("xc-alpha pong");
    });
  });

  describe.skipIf(skipWhenOtherScenario("scope_sub_missing"))("scoped unknown sub", () => {
    it("exits 1 for missing sub scope", () => {
      const r = Bun.spawnSync(
        [
          "zsh",
          xcUsage,
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

  describe.skipIf(skipWhenOtherScenario("list_subs"))("--list-subs", () => {
    it("prints subcommand names one per line", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "dispatcher-docopt.zsh"), "--list-subs"],
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

  describe.skipIf(skipWhenOtherScenario("preview_stacked"))("--preview stacked help", () => {
    it("prints main and sub section headers with optional NAME", () => {
      const r = Bun.spawnSync(
        [
          "zsh",
          xcUsage,
          join(fixtures, "dispatcher-docopt.zsh"),
          "--preview",
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

    it("defaults preview NAME from ##? header", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "dispatcher-docopt.zsh"), "--preview"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      expect(new TextDecoder().decode(r.stdout)).toContain("xc-alpha - Main command:");
    });
  });

  describe.skipIf(skipWhenOtherScenario("metadata"))("dual #? + ##? headers", () => {
    it("--metadata emits only #? lines", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "with-metadata.zsh"), "--metadata"],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("License RIT");
      expect(out).not.toContain("##?");
      expect(out).not.toContain("Usage:");
    });

    it("default emit does NOT include #? metadata", () => {
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "with-metadata.zsh")],
        { stdout: "pipe", stderr: "pipe" },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).not.toContain("License RIT");
      expect(out).toContain("Usage:");
    });
  });

  describe.skipIf(skipWhenOtherScenario("xc_md"))("xc-md markdown rendering", () => {
    it("renders stdin to stdout (cat fallback)", () => {
      const r = Bun.spawnSync(["zsh", xcMd], {
        stdout: "pipe",
        stderr: "pipe",
        stdin: Buffer.from("# Test\n\nHello"),
      });
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Hello");
    });

    it("--md flag delegates to xc-md", () => {
      const binDir = join(repoRoot, "config/bin");
      const r = Bun.spawnSync(
        ["zsh", xcUsage, join(fixtures, "with-docopt.zsh"), "--md"],
        {
          stdout: "pipe",
          stderr: "pipe",
          env: { ...process.env, PATH: `${binDir}:${process.env.PATH ?? ""}` },
        },
      );
      expect(r.exitCode).toBe(0);
      const out = new TextDecoder().decode(r.stdout);
      expect(out).toContain("Usage:");
    });
  });
});
