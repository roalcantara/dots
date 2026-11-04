#!/usr/bin/env bun
// install links ~/.config/gh to config/gh before `gh auth login`, so the login lands in the git-ignored
// config/gh/hosts.yml instead of a real folder that the dotfiles link would refuse to replace.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const INSTALL = readFileSync(join(REPO, "install"), "utf8");
const SNIPPET = INSTALL.match(/# gh-link: begin\n[\s\S]*?# gh-link: end\n/)?.[0] ?? "";

let t: string;
let dots: string;
let ghCfg: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "install-gh-link-"));
  dots = join(t, ".local", "share", "dots");
  mkdirSync(join(dots, "config", "gh"), { recursive: true });
  writeFileSync(join(dots, "config", "gh", "config.yml"), "version: 1\n");
  ghCfg = join(t, ".config", "gh");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet() {
  const p = Bun.spawnSync(["bash", "-c", `set -euo pipefail\nDOTS="${dots}"\n${SNIPPET}`], {
    env: { PATH: "/usr/bin:/bin", HOME: t }, stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, err: p.stderr.toString() };
}
const isLink = (p: string) => existsSync(p) && lstatSync(p).isSymbolicLink();

describe("install gh-link", () => {
  it("is in install, before gh auth login", () => {
    expect(SNIPPET).toContain("config/gh");
    expect(INSTALL.indexOf("# gh-link: begin")).toBeLessThan(INSTALL.indexOf("gh auth login"));
  });

  it("fresh machine: links ~/.config/gh to config/gh, as mise dotfiles would", () => {
    expect(snippet().code).toBe(0);
    expect(isLink(ghCfg)).toBe(true);
    expect(readlinkSync(ghCfg)).toBe("../.local/share/dots/config/gh");
    expect(readFileSync(join(ghCfg, "config.yml"), "utf8")).toBe("version: 1\n");
  });

  it("re-run with a real folder: keeps its login in config/gh (0600), sets the folder aside, links", () => {
    mkdirSync(ghCfg, { recursive: true });
    writeFileSync(join(ghCfg, "hosts.yml"), "github.com:\n    user: me\n");
    expect(snippet().code).toBe(0);
    expect(isLink(ghCfg)).toBe(true);
    expect(readFileSync(join(dots, "config", "gh", "hosts.yml"), "utf8")).toBe("github.com:\n    user: me\n");
    expect(statSync(join(dots, "config", "gh", "hosts.yml")).mode & 0o077).toBe(0);
    const aside = readdirSync(join(t, ".local", "state", "dots")).filter((n) => n.startsWith("pre-install-gh-"));
    expect(aside.length).toBe(1);
  });

  it("never overwrites a login already in config/gh", () => {
    writeFileSync(join(dots, "config", "gh", "hosts.yml"), "kept\n");
    mkdirSync(ghCfg, { recursive: true });
    writeFileSync(join(ghCfg, "hosts.yml"), "other\n");
    expect(snippet().code).toBe(0);
    expect(readFileSync(join(dots, "config", "gh", "hosts.yml"), "utf8")).toBe("kept\n");
    expect(isLink(ghCfg)).toBe(true);
  });

  it("leaves an existing link alone and replaces a broken one", () => {
    mkdirSync(join(t, ".config"), { recursive: true });
    symlinkSync("../.local/share/dots/config/gh", ghCfg);
    expect(snippet().code).toBe(0);
    expect(readlinkSync(ghCfg)).toBe("../.local/share/dots/config/gh");
    rmSync(ghCfg);
    symlinkSync("../nowhere", ghCfg);
    expect(snippet().code).toBe(0);
    expect(readlinkSync(ghCfg)).toBe("../.local/share/dots/config/gh");
  });

  it("does nothing when the checkout has no config/gh (an older branch)", () => {
    rmSync(join(dots, "config", "gh"), { recursive: true });
    expect(snippet().code).toBe(0);
    expect(existsSync(ghCfg) || isLink(ghCfg)).toBe(false);
  });
});
