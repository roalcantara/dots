#!/usr/bin/env bun
// cargo installs (brew bundle `cargo` entries) into $CARGO_HOME/bin, so zsh's and bash's paths must include it:
// otherwise a brew-installed tool (todo) is reachable only through the mise shim it replaces.
import { describe, expect, it } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
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
  it("puts go and cargo installs ahead of the system dirs, so they beat macOS' same-named tools", () => {
    const p = paths({ CARGO_HOME: "/tmp/ch", GOPATH: "/tmp/gp", XDG_DATA_HOME: "/tmp/xdg" });
    expect(p.indexOf("/tmp/gp/bin")).toBeLessThan(p.indexOf("/usr/bin"));
    expect(p.indexOf("/tmp/ch/bin")).toBeLessThan(p.indexOf("/usr/bin"));
  });
  it("keeps the inherited PATH (a misplaced paren once dropped it, and /bin with it)", () => {
    expect(paths({ XDG_DATA_HOME: "/tmp/xdg" })).toEqual(expect.arrayContaining(["/usr/bin", "/bin"]));
  });
});

// env::homebrew runs after env::paths and prepends the brew prefix: that, not env::paths' order, keeps rustup's
// proxies in $CARGO_HOME/bin from shadowing brew's cargo. It only runs where a Homebrew prefix exists.
const hasBrewPrefix = ["/opt/homebrew", "/home/linuxbrew/.linuxbrew", "/usr/local/Homebrew"].some((d) => existsSync(d));
describe.skipIf(!Bun.which("zsh") || !hasBrewPrefix)("zsh env::paths then env::homebrew", () => {
  it("puts brew's bin ahead of $CARGO_HOME/bin, so rustup's proxies never shadow cargo", () => {
    const p = Bun.spawnSync(["zsh", "-fc", "source config/zsh/opt/rc.d/env.zsh; env::paths; env::homebrew; print -l $path"], {
      cwd: ROOT,
      // A prefix with no brew binary: env::homebrew prepends its dirs without running `brew shellenv`.
      env: { HOME: process.env.HOME as string, PATH: "/usr/bin:/bin", CARGO_HOME: "/tmp/ch", XDG_DATA_HOME: "/tmp/xdg", HOMEBREW_PREFIX: "/tmp/hb" },
      stdout: "pipe", stderr: "pipe",
    }).stdout.toString().split("\n");
    expect(p.indexOf("/tmp/hb/bin")).toBeGreaterThan(-1);
    expect(p.indexOf("/tmp/hb/bin")).toBeLessThan(p.indexOf("/tmp/ch/bin"));
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
