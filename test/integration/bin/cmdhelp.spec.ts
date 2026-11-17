#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { existsSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { scriptPath } from "./support/paths";

const script = scriptPath("cmdhelp");

// A fake CLI: logs every call, prints help for itself and its `run`/`list` subcommands, and "runs" anything else.
const FAKE = `#!/bin/sh
echo "$*" >> "$FAKE_LOG"
case "$*" in
  --help) printf 'Usage: fake <COMMAND>\\n\\nCommands:\\n  run   Run a thing\\n  list  List things\\n\\nOptions:\\n  -v, --verbose  Be loud\\n  -h, --help     Print help\\n' ;;
  "run --help") printf 'Usage: fake run [OPTIONS] <IMAGE>\\n\\nOptions:\\n      --rm         Remove after\\n      --tag <TAG>  Tag it\\n                   (comma-separated)\\n  -h, --help       Print help\\n' ;;
  "list --help") printf 'Usage: fake list\\n\\nList things\\n' ;;
  *) echo "RAN $*"; exit 2 ;;
esac
`;

const setup = () => {
  const dir = mkdtempSync(join(tmpdir(), "cmdhelp-"));
  writeFileSync(join(dir, "fake"), FAKE, { mode: 0o755 });
  return dir;
};

const run = (args: string[], color = false) => {
  const dir = setup();
  const log = join(dir, "log");
  const env: Record<string, string> = { HOME: process.env.HOME ?? "", PATH: `${dir}:${process.env.PATH}`, FAKE_LOG: log };
  if (!color) env.NO_COLOR = "1";
  const r = Bun.spawnSync([script, ...args], { env, stdout: "pipe", stderr: "pipe" });
  return {
    out: r.stdout.toString(),
    err: r.stderr.toString(),
    calls: existsSync(log) ? readFileSync(log, "utf8").split("\n").filter(Boolean) : [],
  };
};

describe("cmdhelp", () => {
  it("a listed subcommand shows its own --help", () => {
    const r = run(["run", "fake", ""]);
    expect(r.out).toContain("Usage: fake run [OPTIONS] <IMAGE>");
    expect(r.calls).toEqual(["--help", "run --help"]);
  });

  it("a flag shows its lines first, then the command's help", () => {
    const r = run(["--tag", "fake", "run", "--t"]);
    const lines = r.out.split("\n");
    expect(lines[0]).toContain("--tag <TAG>  Tag it");
    expect(lines[1]).toContain("(comma-separated)");
    expect(r.out).toContain("Usage: fake run");
  });

  it("never runs a word the parent's help does not list", () => {
    const r = run(["--rm", "fake", "run", "ubuntu", "--"]);
    expect(r.out).toContain("--rm");
    expect(r.calls.some((c) => c.includes("ubuntu"))).toBe(false);
  });

  it("an unlisted candidate shows nothing and runs nothing with it", () => {
    const r = run(["ubuntu", "fake", "run", ""]);
    expect(r.out).toBe("");
    expect(r.calls.some((c) => c.includes("ubuntu"))).toBe(false);
  });

  it("a command name (no command before it) runs nothing", () => {
    const r = run(["fake", "fa"]);
    expect(r.out).toBe("");
    expect(r.calls).toEqual([]);
  });

  it.skipIf(!Bun.which("bat"))("colours the help with bat unless NO_COLOR is set", () => {
    expect(run(["run", "fake", ""], true).out).toContain("\x1b[");
    expect(run(["run", "fake", ""]).out).not.toContain("\x1b[");
  });
});
