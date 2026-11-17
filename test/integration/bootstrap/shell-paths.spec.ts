#!/usr/bin/env bun
// cargo installs (brew bundle `cargo` entries) into $CARGO_HOME/bin, so zsh's and bash's paths must include it:
// otherwise a brew-installed tool (todo) is reachable only through the mise shim it replaces.
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "../../..");

const paths = (env: Record<string, string>) => {
  const p = Bun.spawnSync(["zsh", "-fc", "source config/zsh/opt/rc.d/env.zsh; env::paths; print -l $path"], {
    cwd: ROOT,
    env: { HOME: process.env.HOME as string, PATH: "/usr/bin:/bin", ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  return p.stdout.toString().split("\n");
};

describe.skipIf(!Bun.which("zsh"))("zsh env::paths", () => {
  it("adds $CARGO_HOME/bin, not $CARGO_HOME", () => {
    const p = paths({ CARGO_HOME: "/tmp/ch", XDG_DATA_HOME: "/tmp/xdg" });
    expect(p).toContain("/tmp/ch/bin");
    expect(p).not.toContain("/tmp/ch");
  });
  it("falls back to $XDG_DATA_HOME/cargo/bin", () => {
    expect(paths({ XDG_DATA_HOME: "/tmp/xdg" })).toContain("/tmp/xdg/cargo/bin");
  });
  it("puts it last, so rustup's proxies never shadow cargo", () => {
    const p = paths({ CARGO_HOME: "/tmp/ch", XDG_DATA_HOME: "/tmp/xdg" }).filter(Boolean);
    expect(p.at(-1)).toBe("/tmp/ch/bin");
  });
});

// Agents run their commands in bash (agent-shell.spec.ts), so bashrc's PATH line needs the same fix.
const bashPathLine = readFileSync(join(ROOT, "config/bash/bashrc"), "utf8")
  .split("\n").find((l) => l.startsWith("export PATH=") && l.includes("CARGO_HOME")) as string;
const bashPaths = (env: Record<string, string>) => {
  const p = Bun.spawnSync(["bash", "--norc", "--noprofile", "-c", `${bashPathLine}; printf '%s\\n' "$PATH" | tr : '\\n'`], {
    env: { HOME: process.env.HOME as string, PATH: "/usr/bin:/bin", ...env }, stdout: "pipe", stderr: "pipe",
  });
  return p.stdout.toString().split("\n").filter(Boolean);
};

describe("bashrc PATH", () => {
  it("adds $CARGO_HOME/bin, not $CARGO_HOME, last", () => {
    const p = bashPaths({ CARGO_HOME: "/tmp/ch", XDG_DATA_HOME: "/tmp/xdg" });
    expect(p).not.toContain("/tmp/ch");
    expect(p.at(-1)).toBe("/tmp/ch/bin");
  });
  it("falls back to $XDG_DATA_HOME/cargo/bin", () => {
    expect(bashPaths({ XDG_DATA_HOME: "/tmp/xdg" }).at(-1)).toBe("/tmp/xdg/cargo/bin");
  });
});
