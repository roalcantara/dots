#!/usr/bin/env bun
// Risky commands (rm -rf, git push --force, …) get the theme's warning colour while typed.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
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
  writeFileSync(join(dir, "config.toml"), '[theme]\nname = "catppuccin-mocha"\n');
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
      `DOTS_CONFIG=${join(dir, "config.toml")}`,
      `DOTS_THEME_LINK=${join(dir, "link")}`,
      "DOTS_ZSH_PATINA=true",
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

// The hook runs on every keystroke, so a function that errors would spray the terminal while typing. Merge stderr
// and keep only the plugin's own complaints.
const hookErrors = (buffer: string) =>
  zsh(`{ BUFFER=${JSON.stringify(buffer)}; _dots_warn_highlight } 2>&1`)
    .split("\n")
    .filter((line) => line.includes("_dots_warn"));

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
  it("flags of a later command never count for the risky one", () => {
    expect(marked("rm -r d; ls -f")).toBe(false);
    expect(marked("chmod -R 755 x; echo 777")).toBe(false);
    expect(warnRegion("git push -f && ls -la")).toMatch(/^0 11 /);
  });
  it("keywords as arguments do not start a command", () => {
    expect(marked("echo sudo rm x")).toBe(false);
    expect(marked("echo do rm -rf x")).toBe(false);
    expect(warnRegion("if true; then rm -rf x; fi")).toMatch(/^14 20 /);
  });
  it("a risky command on a later line is cued there", () => {
    // $'…' so zsh gets a real newline; a double-quoted "\n" stays two characters.
    const out = zsh(`BUFFER=$'ls\\nrm -rf x'; _dots_warn_highlight; print -rl -- $region_highlight`);
    expect(out.split("\n").find((line) => line.toLowerCase().includes(WARN_STYLE))).toMatch(/^3 9 /);
  });
  it("the hook never fails, so the line-pre-redraw widgets after it still run", () => {
    // add-zle-hook-widget's dispatcher stops at the first widget that returns non-zero (p10k's, Lig's…).
    for (const buffer of ["", "ls", "rm -rf x"]) {
      expect(zsh(`BUFFER=${JSON.stringify(buffer)}; _dots_warn_highlight; print -r -- "rc=$?"`)).toContain("rc=0");
    }
  });
  it("a bare git stays quiet", () => {
    expect(hookErrors("git")).toEqual([]);
    expect(hookErrors("git ")).toEqual([]);
    expect(marked("git")).toBe(false);
  });
});
