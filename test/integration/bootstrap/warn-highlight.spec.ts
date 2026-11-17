#!/usr/bin/env bun
// Risky commands (rm -rf, git push --force, …) get the theme's warning colour while typed.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { repoRoot } from "../bin/support/paths";

const HOME = process.env.HOME as string;
const THEMES = join(repoRoot, "config/theme/themes");
const MOCHA = join(THEMES, "catppuccin-mocha");

const WARN_STYLE = (() => {
  const env = readFileSync(join(MOCHA, "env.zsh"), "utf8");
  const match = env.match(/export DOTS_WARN_STYLE="([^"]+)"/);
  if (!match) throw new Error("env.zsh has no DOTS_WARN_STYLE");
  return match[1].toLowerCase();
})();

let dir = "";
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "dots-warn-"));
});
afterAll(() => rmSync(dir, { recursive: true, force: true }));

// No tty: the zle hook's body is called directly, because a pre-redraw hook needs real keystrokes to fire and
// completing "rm x" in a pty opens a completion menu instead of returning.
const zsh = (script: string) => {
  const r = Bun.spawnSync(
    [
      "env",
      "-i",
      `HOME=${HOME}`,
      `PATH=${process.env.PATH}`,
      `ZIM_HOME=${process.env.ZIM_HOME ?? join(HOME, ".local/state/zim")}`,
      "TERM=xterm-256color",
      `ZDOTDIR=${HOME}/.config/zsh`,
      `DOTS_THEME_LINK=${MOCHA}`,
      `DOTS_THEMES_DIR=${THEMES}`,
      "zsh",
      "-ic",
      script,
    ],
    { stdout: "pipe", stderr: "pipe" },
  );
  return r.stdout.toString().replace(/\r/g, "").replace(/^\^D\n?/, "");
};

const regions = (buffer: string) =>
  zsh(`BUFFER=${JSON.stringify(buffer)}; _dots_warn_highlight; print -rl -- $region_highlight`)
    .split("\n")
    .filter(Boolean);

const marked = (buffer: string) => regions(buffer).some((line) => line.toLowerCase().includes(WARN_STYLE));

const warnRegion = (buffer: string) =>
  regions(buffer).find((line) => line.toLowerCase().includes(WARN_STYLE)) ?? "";

describe("risky commands get the warning colour", () => {
  it("the hook is registered", () => {
    const out = zsh('print -r -- "$+functions[_dots_warn_highlight]|${widgets[zle-line-pre-redraw]}"');
    expect(out).toContain("1|");
    expect(out).toMatch(/1\|user:azhw:/);
  });
  it("rm -rf x is marked", () => expect(marked("rm -rf x")).toBe(true));
  it("git push --force is marked", () => expect(marked("git push --force")).toBe(true));
  it("rm x is not marked", () => expect(marked("rm x")).toBe(false));
  it("rm-rf-notes.txt is not marked", () => expect(marked("cat rm-rf-notes.txt")).toBe(false));
  it("the cue covers the command and its flags, not the operand", () => {
    expect(warnRegion("rm -rf x")).toMatch(/^0 6 /);
    expect(warnRegion("chmod -R 777 dir")).toMatch(/^0 12 /);
    expect(warnRegion("git push --force origin")).toMatch(/^0 16 /);
  });
  it("the cue starts at the command after a separator", () => {
    expect(warnRegion("echo hi; rm -rf x")).toMatch(/^9 15 /);
  });
  it("sudo rm cues rm, not sudo", () => expect(warnRegion("sudo rm x")).toMatch(/^5 7 /));
});
