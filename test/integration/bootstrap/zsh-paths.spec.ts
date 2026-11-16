#!/usr/bin/env bun
// cargo installs (brew bundle `cargo` entries) into $CARGO_HOME/bin, so zsh's path must include that directory:
// otherwise a brew-installed tool (todo) is reachable only through the mise shim it replaces.
import { describe, expect, it } from "bun:test";
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
