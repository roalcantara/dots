#!/usr/bin/env bun
// The shell reads the active theme: zsh's theme.zsh and bash's bashrc export the theme folder's values.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { mkdtempSync, readFileSync, readdirSync, rmSync, statSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { repoRoot } from "../bin/support/paths";

const HOME = process.env.HOME as string;
const THEMES = join(repoRoot, "config/theme/themes");

let dir = "";
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "dots-theme-env-"));
});
afterAll(() => rmSync(dir, { recursive: true, force: true }));

// `script` makes zim and fzf load, as they would in a terminal. The output carries \r and a leading ^D.
const envOf = (shell: "zsh" | "bash", link: string, script: string) => {
  const r = Bun.spawnSync(
    [
      "env",
      "-i",
      `HOME=${HOME}`,
      "TERM=xterm-256color",
      `ZDOTDIR=${HOME}/.config/zsh`,
      `DOTS_THEME_LINK=${link}`,
      `DOTS_THEMES_DIR=${THEMES}`,
      "script",
      "-q",
      "/dev/null",
      shell,
      "-ic",
      script,
    ],
    { stdout: "pipe", stderr: "pipe" },
  );
  return r.stdout.toString().replace(/\r/g, "").replace(/^\^D\n?/, "");
};

const zsh = (link: string, script: string) => envOf("zsh", link, script);
const bash = (link: string, script: string) => envOf("bash", link, script);

describe("the shell reads the theme", () => {
  it("mocha exports its values", () => {
    const out = zsh(
      join(THEMES, "catppuccin-mocha"),
      'print -r -- "$BAT_THEME|$EZA_CONFIG_DIR|$LS_COLORS"',
    );
    expect(out).toContain("Catppuccin Mocha|");
    expect(out).toContain("catppuccin-mocha/eza");
    expect(out).toContain("di=");
  });

  it("macchiato exports its values", () => {
    const out = zsh(
      join(THEMES, "catppuccin-macchiato"),
      'print -r -- "$BAT_THEME|$EZA_CONFIG_DIR|$LS_COLORS"',
    );
    expect(out).toContain("Catppuccin Macchiato|");
    expect(out).toContain("catppuccin-macchiato/eza");
    expect(out).toContain("di=");
  });

  it("a dangling link falls back to mocha, silently", () => {
    const link = join(dir, "dangling");
    symlinkSync(join(dir, "missing"), link);
    const out = zsh(link, 'print -r -- "$BAT_THEME"');
    expect(out).toContain("Catppuccin Mocha");
    expect(out.toLowerCase()).not.toContain("no such file");
  });

  it("bash reads the theme", () => {
    const out = bash(join(THEMES, "catppuccin-macchiato"), "echo $BAT_THEME");
    expect(out).toContain("Catppuccin Macchiato");
  });

  it("no Dracula left", () => {
    const roots = ["config/zsh", "config/bash", "config/bin", "config/bat", "config/git", "config/mise", "config/television"];
    const files = roots.flatMap((root) => {
      const walk = (p: string): string[] =>
        statSync(p).isDirectory()
          ? readdirSync(p).flatMap((e) => walk(join(p, e)))
          : p.endsWith(".zwc")
            ? []
            : [p];
      return walk(join(repoRoot, root));
    });
    for (const file of files) {
      const text = readFileSync(file, "utf8");
      expect({ file, dracula: /dracula/i.test(text) }).toEqual({ file, dracula: false });
      // Markdown documents tools' own flags (bat's README shows --theme=TwoDark); settings must not set one.
      if (!file.endsWith(".md")) {
        expect({ file, batTheme: /--theme=/.test(text) }).toEqual({ file, batTheme: false });
      }
    }
  });
});
