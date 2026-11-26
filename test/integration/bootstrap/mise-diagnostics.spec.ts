#!/usr/bin/env bun
// mise run mise:diagnostics: the only CLI that reports deprecated-key is `mise lsp`, so this drives it over
// stdio and prints the diagnostics the editor shows.
import { describe, expect, it } from "bun:test";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const SCRIPT = join(REPO, ".mise/tasks/mise/diagnostics.ts");
const FIXTURES = join(import.meta.dir, "fixtures");

const maybe = Bun.which("mise") ? describe : describe.skip;

function run(args: string[] = []) {
  const p = Bun.spawnSync(["bun", SCRIPT, ...args], {
    cwd: REPO,
    env: {
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      HOME: process.env.HOME ?? "/tmp",
      DOTS_DIR: REPO,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

maybe("mise:diagnostics", () => {
  it("reports deprecated-key with file and line for the fixture", () => {
    const r = run([join(FIXTURES, "mise-deprecated.toml")]);
    expect(r.code).toBe(1);
    const line = r.out.trim().split("\n")[0];
    expect(line).toContain("mise-deprecated.toml:1");
    expect(line).toContain("\tdeprecated-key\t");
  });

  it("prints nothing and exits 0 for a clean file", () => {
    const r = run([join(FIXTURES, "mise-clean.toml")]);
    expect(r.code).toBe(0);
    expect(r.out).toBe("");
  });

  it("default file set is clean", () => {
    const r = run();
    expect(r.code).toBe(0);
    expect(r.out).toBe("");
  });
});
