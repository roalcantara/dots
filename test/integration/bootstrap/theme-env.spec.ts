#!/usr/bin/env bun
// The shell reads the active theme: zsh's theme.zsh and bash's bashrc export the theme folder's values.
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, readlinkSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { repoRoot } from "../bin/support/paths";

const HOME = process.env.HOME as string;
const THEMES = join(repoRoot, "config/theme/themes");

let dir = "";
// A fake gomi on PATH lets the rm safety net be tested without moving real files to the trash.
let fakeBin = "";
beforeAll(() => {
  dir = mkdtempSync(join(tmpdir(), "dots-theme-env-"));
  fakeBin = join(dir, "bin");
  mkdirSync(fakeBin, { recursive: true });
  writeFileSync(join(fakeBin, "gomi"), "#!/bin/sh\nexit 0\n", { mode: 0o755 });
});
afterAll(() => rmSync(dir, { recursive: true, force: true }));

// The theme comes from a dots config file (config/dots/config.toml); each call writes its own, plus its own link path,
// so a test never touches the real ones. `theme` is a theme name or folder; `eza` the optional eza override.
let calls = 0;
const configFor = (theme: string, eza?: string) => {
  const name = theme.split("/").pop() as string;
  const file = join(dir, `config-${++calls}.toml`);
  writeFileSync(file, `[theme]\nname = "${name}"\n${eza ? `eza = "${eza}"\n` : ""}`);
  return { DOTS_CONFIG: file, DOTS_THEME_LINK: join(dir, `link-${calls}`) };
};

// `script` makes zim and fzf load, as they would in a terminal. The output carries \r and a leading ^D.
const envOf = (shell: "zsh" | "bash", theme: string, script: string, extra: Record<string, string> = {}) => {
  const env = { ...configFor(theme), DOTS_ZSH_PATINA: "true", ...extra };
  const r = Bun.spawnSync(
    [
      "env",
      "-i",
      `HOME=${HOME}`,
      "TERM=xterm-256color",
      `ZDOTDIR=${HOME}/.config/zsh`,
      `DOTS_THEMES_DIR=${THEMES}`,
      ...Object.entries(env).map(([name, value]) => `${name}=${value}`),
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

const zsh = (theme: string, script: string, extra?: Record<string, string>) => envOf("zsh", theme, script, extra);
const bash = (theme: string, script: string, extra?: Record<string, string>) => envOf("bash", theme, script, extra);
const lsColors = (theme: string) => (readFileSync(join(THEMES, theme, "ls_colors"), "utf8").match(/LS_COLORS='([^']+)'/) as string[])[1];

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

  it("colours inherited from the pre-theme palette never override the theme", () => {
    // eza prefers EZA_COLORS/EXA_COLORS to its theme.yml; the old theme.zsh exported these, and apps started before
    // the switch still pass them on.
    const stale = { EXA_COLORS: "di=1;38;2;122;162;247", EZA_COLORS: "di=31", LSCOLORS: "EgCeDdEeCcghhahahacac" };
    for (const shell of [zsh, bash]) {
      const out = shell(join(THEMES, "catppuccin-mocha"), 'echo "[${EXA_COLORS-}|${EZA_COLORS-}|${LSCOLORS-}]"', stale);
      expect(out).toContain("[||]");
    }
  });

  it("an unknown theme name says so once and leaves the tools on their own colours", () => {
    const out = zsh("nope", 'print -r -- "[$BAT_THEME|${DOTS_THEME_DIR-}]"');
    expect(out).toContain("[|]");
    expect(out.match(/unknown theme/g)).toHaveLength(1);
  });

  for (const shell of ["zsh", "bash"] as const) {
    it(`eza and ls colours come from the eza theme, the rest from the theme (${shell})`, () => {
      const env = configFor("tokyonight-storm", "dracula");
      const out = envOf(shell, "tokyonight-storm", 'echo "$BAT_THEME|$EZA_CONFIG_DIR|[${EZA_COLORS-}]"; echo "$LS_COLORS"', env);
      expect(out).toContain(`tokyonight_storm|${THEMES}/dracula/eza|[]`);
      expect(out).toContain(lsColors("dracula"));
    });

    it(`without eza, the theme's own eza colours apply (${shell})`, () => {
      const out = envOf(shell, "tokyonight-storm", 'echo "$EZA_CONFIG_DIR|${#EZA_COLORS}"; echo "$LS_COLORS"');
      expect(out).toContain(`${THEMES}/tokyonight-storm/eza|`);
      expect(out).not.toContain("/eza|0");
      expect(out).toContain(lsColors("tokyonight-storm"));
    });
  }

  it("a new shell points the theme link at the file's theme, for Ghostty and Lig", () => {
    const env = configFor("catppuccin-macchiato");
    zsh("catppuccin-macchiato", "true", env);
    expect(readlinkSync(env.DOTS_THEME_LINK)).toBe(join(THEMES, "catppuccin-macchiato"));
  });

  it("the committed config is the owner's: Tokyo Night Storm, with Dracula's eza colours", () => {
    const config = Bun.TOML.parse(readFileSync(join(repoRoot, "config/dots/config.toml"), "utf8")) as any;
    expect(config.theme).toEqual({ name: "tokyonight-storm", eza: "dracula" });
    expect(existsSync(join(THEMES, config.theme.name))).toBe(true);
    expect(existsSync(join(THEMES, config.theme.eza))).toBe(true);
  });

  it("bash reads the theme", () => {
    const out = bash(join(THEMES, "catppuccin-macchiato"), "echo $BAT_THEME");
    expect(out).toContain("Catppuccin Macchiato");
  });

  it("no Dracula left outside the dracula theme", () => {
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
      // `dracula` is also a theme name (config/theme/themes/dracula): dots theme's usage `choices` lines list it,
      // quoted in config/bin/dots and bare in the generated _dots.
      expect({ file, dracula: /dracula/i.test(text.replace(/^.*\bchoices\b.*$/gm, "")) }).toEqual({ file, dracula: false });
      // Markdown documents tools' own flags (bat's README shows --theme=TwoDark); settings must not set one.
      if (!file.endsWith(".md")) {
        expect({ file, batTheme: /--theme=/.test(text) }).toEqual({ file, batTheme: false });
      }
    }
  });
});

describe("the rm safety net", () => {
  const withGomi = () => ({ PATH: `${fakeBin}:${process.env.PATH}` });

  it("rm is gomi in an interactive shell", () => {
    const out = zsh(join(THEMES, "catppuccin-mocha"), "whence -w rm; alias rm", withGomi());
    expect(out).toContain("rm: alias");
    expect(out).toMatch(/^rm=gomi$/m);
  });

  it("rm stays rm in zsh -c and bash -c", () => {
    const realRm = (shell: "zsh" | "bash", script: string) =>
      Bun.spawnSync(
        ["env", "-i", `HOME=${HOME}`, `PATH=${withGomi().PATH}`, `ZDOTDIR=${HOME}/.config/zsh`, shell, "-c", script],
        { stdout: "pipe", stderr: "pipe" },
      )
        .stdout.toString()
        .trim();
    expect(realRm("zsh", "whence -p rm")).toMatch(/^\/(bin|usr\/bin)\/rm$/);
    expect(realRm("bash", "type -P rm")).toMatch(/^\/(bin|usr\/bin)\/rm$/);
  });

  it("no gomi, no alias", () => {
    // A missing file would also leave rm unaliased: assert the safety net file itself loaded.
    const out = zsh(
      join(THEMES, "catppuccin-mocha"),
      'unalias rm 2>/dev/null; path=(/usr/bin /bin); hash -r; source "$ZDOTDIR/opt/aliases/safety.zsh"; whence -w rm',
    );
    expect(out).toContain("rm: command");
    expect(out).not.toContain("rm: alias");
    expect(out).not.toContain("no such file");
  });
});
