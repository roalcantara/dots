#!/usr/bin/env bun
// The tiling setup (docs/superpowers/specs/2026-11-07-yabai-omarchy-design.md): packages, the fn key
// default, the links bootstrap makes, and the services and rules around yabai.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (p: string) => readFileSync(join(REPO, p), "utf8");
const toml = (p: string) => Bun.TOML.parse(read(p)) as any;

describe("tiling packages and links", () => {
  const brewfile = read("config/homebrew/Brewfile");
  const macos = toml("config/mise/conf.d/macos.toml");
  const dotfiles = toml("config/mise/conf.d/dotfiles.toml");

  it("installs yabai, JankyBorders and Karabiner-Elements on macOS", () => {
    expect(brewfile).toMatch(/^brew "asmvik\/formulae\/yabai", trusted: true if OS\.mac\?/m);
    expect(brewfile).toMatch(/^brew "FelixKratz\/formulae\/borders", trusted: true if OS\.mac\?/m);
    expect(brewfile).toMatch(/^cask "karabiner-elements" if OS\.mac\?/m);
  });

  it("sets the fn (Globe) key to do nothing", () => {
    expect(macos.bootstrap.macos.defaults["com.apple.HIToolbox"].AppleFnUsageType).toBe(0);
  });

  it("links ~/.config/karabiner and ~/.config/borders as whole folders", () => {
    for (const name of ["karabiner", "borders"]) {
      expect(dotfiles.dotfiles[`~/.config/${name}`]).toEqual({ source: `~/.local/share/dots/config/${name}`, relative: true });
    }
  });

  describe("pre-dotfiles hook", () => {
    const HOOK: string = dotfiles.bootstrap.hooks["pre-dotfiles"].run;
    let t: string;
    beforeEach(() => {
      t = mkdtempSync(join(tmpdir(), "yabai-links-"));
    });
    afterEach(() => rmSync(t, { recursive: true, force: true }));

    const run = () => {
      const bin = join(t, "bin");
      mkdirSync(bin, { recursive: true });
      writeFileSync(join(bin, "uname"), "#!/bin/sh\necho Darwin\n");
      chmodSync(join(bin, "uname"), 0o755);
      return Bun.spawnSync(["sh", "-o", "errexit", "-c", HOOK], {
        env: { PATH: `${bin}:/usr/bin:/bin`, HOME: t, DOTS_VSCODE_USER: join(t, "Code", "User") },
        stdout: "pipe",
        stderr: "pipe",
      });
    };
    const config = () => join(t, ".config");

    it("moves a real ~/.config/karabiner aside, keeping its content", () => {
      mkdirSync(join(config(), "karabiner"), { recursive: true });
      writeFileSync(join(config(), "karabiner", "karabiner.json"), "{}\n");
      expect(run().exitCode).toBe(0);
      expect(existsSync(join(config(), "karabiner"))).toBe(false);
      const [moved] = readdirSync(config()).filter((f) => f.startsWith("karabiner.pre-dots-"));
      expect(moved).toMatch(/^karabiner\.pre-dots-\d{14}$/);
      expect(readFileSync(join(config(), moved!, "karabiner.json"), "utf8")).toBe("{}\n");
    });

    it("leaves the dots link alone", () => {
      mkdirSync(config(), { recursive: true });
      symlinkSync(join(REPO, "config/karabiner"), join(config(), "karabiner"));
      expect(run().exitCode).toBe(0);
      expect(lstatSync(join(config(), "karabiner")).isSymbolicLink()).toBe(true);
    });
  });
});
