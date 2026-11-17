#!/usr/bin/env bun
// The shell theme folders, `mise run theme:build` and `dots theme` (docs/THEME.md).
import { afterAll, beforeAll, describe, expect, it } from "bun:test";
import {
  chmodSync,
  existsSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  readlinkSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { realUsageDir, repoRoot } from "./support/paths";

const THEMES = join(repoRoot, "config/theme/themes");
const NAMES = ["catppuccin-mocha", "catppuccin-macchiato", "tokyonight-storm-custom", "dracula", "tokyonight-storm"];

// One file per tool, plus the vendored eza theme and its licence.
const FILES = [
  "theme.ghostty",
  "env.zsh",
  "env.bash",
  "ls_colors",
  "eza/theme.yml",
  "eza/LICENSE",
  "zsh-patina.toml",
  "lig.toml",
  "eza.sh",
];

const vivid = Bun.which("vivid");

describe("theme folders", () => {
  it("each theme has every file", () => {
    for (const name of NAMES) {
      for (const file of FILES) {
        const path = join(THEMES, name, file);
        expect({ name, file, exists: existsSync(path) }).toEqual({ name, file, exists: true });
        expect({ name, file, empty: statSync(path).size === 0 }).toEqual({ name, file, empty: false });
      }
    }
  });

  it("ls_colors is one export line, after a comment when hand-made", () => {
    for (const name of NAMES) {
      expect(readFileSync(join(THEMES, name, "ls_colors"), "utf8")).toMatch(/^(# hand-made[^\n]*\n)?export LS_COLORS='[^']+'\n$/);
    }
  });

  it("tokyonight-storm keeps the pre-theme palette: the old LS_COLORS and eza colours", () => {
    // The hand-made palette theme.zsh exported before the switchable theme (796affa).
    const old = Bun.spawnSync(["git", "show", "796affa:config/zsh/opt/rc.d/theme.zsh"], { cwd: repoRoot, stdout: "pipe" }).stdout.toString();
    const value = (key: string) => old.match(new RegExp(`export ${key}="([^"]+)"`))?.[1] as string;
    const dir = join(THEMES, "tokyonight-storm");
    expect(readFileSync(join(dir, "ls_colors"), "utf8")).toContain(`export LS_COLORS='${value("LS_COLORS")}'`);
    expect(readFileSync(join(dir, "eza.sh"), "utf8")).toContain(`export EZA_COLORS="${value("EXA_COLORS")}"`);
  });

  it("dracula's eza colours are Dracula's own (draculatheme.com/eza), in truecolor", () => {
    // dracula/eza's EZA_COLORS uses the terminal's basic colours (34 = Dracula purple, 95 = bright pink, …); here they
    // are Dracula's hex values, so they hold under any terminal palette. File names stay white: no per-extension colours.
    const eza = readFileSync(join(THEMES, "dracula/eza.sh"), "utf8");
    for (const key of ["ur=38;2;189;147;249", "uw=38;2;255;146;223", "ux=38;2;139;233;253", "gw=38;2;255;121;198", "da=2;38;2;189;147;249", "xx=38;2;255;146;223", "uu=38;2;139;233;253", "uR=38;2;255;85;85"]) {
      expect(eza).toContain(key);
    }
    const ls = readFileSync(join(THEMES, "dracula/ls_colors"), "utf8");
    expect(ls).toStartWith("# hand-made");
    expect(ls).toContain("di=1;38;2;189;147;249");
    expect(ls).not.toContain("*.");
  });

  it("theme:build leaves a hand-made ls_colors alone", () => {
    const before = readFileSync(join(THEMES, "tokyonight-storm/ls_colors"), "utf8");
    const r = Bun.spawnSync(["mise", "run", "theme:build", "tokyonight-storm"], { cwd: repoRoot, stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).toBe(0);
    expect(r.stdout.toString() + r.stderr.toString()).toContain("hand-made");
    expect(readFileSync(join(THEMES, "tokyonight-storm/ls_colors"), "utf8")).toBe(before);
  });

  it("eza and ls colours live only in eza.sh, so another theme's can stand in (config/dots/config.toml eza)", () => {
    for (const name of NAMES) {
      for (const env of ["env.zsh", "env.bash"]) {
        expect({ name, env, text: /EZA_|ls_colors/.test(readFileSync(join(THEMES, name, env), "utf8")) }).toEqual({ name, env, text: false });
      }
      expect(readFileSync(join(THEMES, name, "eza.sh"), "utf8")).toContain('EZA_CONFIG_DIR="$DOTS_EZA_DIR/eza"');
    }
  });

  it("each BAT_THEME is built into bat or vendored in config/bat/themes", () => {
    const builtIn = Bun.spawnSync(["bat", "--list-themes", "--color=never"], { stdout: "pipe" }).stdout.toString().split("\n");
    for (const name of NAMES) {
      const theme = readFileSync(join(THEMES, name, "env.zsh"), "utf8").match(/export BAT_THEME="([^"]+)"/)?.[1] as string;
      expect({ name, theme, found: builtIn.includes(theme) || existsSync(join(repoRoot, `config/bat/themes/${theme}.tmTheme`)) }).toEqual({ name, theme, found: true });
    }
  });

  it.skipIf(!vivid)("theme:build reproduces every ls_colors", () => {
    // Compared with the files as they are, not with git, so an unrelated edit under config/theme cannot fail it.
    const read = () => Object.fromEntries(NAMES.map((name) => [name, readFileSync(join(THEMES, name, "ls_colors"), "utf8")]));
    const before = read();
    const build = Bun.spawnSync(["mise", "run", "theme:build"], { cwd: repoRoot, stdout: "pipe", stderr: "pipe" });
    expect(build.exitCode).toBe(0);
    expect(read()).toEqual(before);
  });

  it("theme:build rejects an unknown name", () => {
    const r = Bun.spawnSync(["mise", "run", "theme:build", "nope"], { cwd: repoRoot, stdout: "pipe", stderr: "pipe" });
    expect(r.exitCode).not.toBe(0);
    const output = r.stdout.toString() + r.stderr.toString();
    expect(output).toContain("catppuccin-mocha");
    expect(output).toContain("catppuccin-macchiato");
  });
});

// The choices a usage spec declares, sorted.
const choicesIn = (text: string) =>
  [...text.matchAll(/choices((?:\s+"[^"]+")+)/g)]
    .flatMap((m) => [...m[1].matchAll(/"([^"]+)"/g)].map((c) => c[1]))
    .sort();

// Lig reads one file and has no include, so every theme carries the whole config; only [ui] and [colors] differ.
const ligConfig = (name: string) => Bun.TOML.parse(readFileSync(join(THEMES, name, "lig.toml"), "utf8")) as Record<string, any>;
const LIG_COLORS = [
  "bg",
  "fg",
  "selected_bg",
  "selected_fg",
  "match_fg",
  "description_fg",
  "selected_description_fg",
  "border_fg",
  "scrollbar_fg",
  "info_fg",
];

describe("Lig's config", () => {
  it("lig.toml is the same in every theme but [ui] and [colors]", () => {
    const shared = NAMES.map((name) => {
      const { ui: _ui, colors: _colors, ...rest } = ligConfig(name);
      return rest;
    });
    for (const rest of shared) expect(rest).toEqual(shared[0]);
  });

  it("lig.toml asks zsh's completion, and leaves Ctrl-R and the network alone", () => {
    for (const name of NAMES) {
      const { behavior } = ligConfig(name);
      expect(behavior.completers).toEqual(["shell"]);
      expect(behavior.online).toBe(false);
      expect(behavior.history).toBe(false);
    }
  });

  it("each lig.toml sets the colours explicitly", () => {
    for (const name of NAMES) {
      const { ui, colors } = ligConfig(name);
      expect(["catppuccin", "tokyonight", "dracula", "nord", "gruvbox"]).toContain(ui.theme);
      for (const key of LIG_COLORS) expect({ name, key, value: colors[key] }).toEqual({ name, key, value: expect.stringMatching(/^#[0-9a-f]{6}$/i) });
    }
    expect(ligConfig("catppuccin-mocha").colors.bg.toLowerCase()).toBe("#1e1e2e");
    expect(ligConfig("catppuccin-macchiato").colors.bg.toLowerCase()).toBe("#24273a");
    expect(ligConfig("tokyonight-storm").colors.bg.toLowerCase()).toBe("#1f2335");
    expect(ligConfig("dracula").colors.bg.toLowerCase()).toBe("#282a36");
  });

  it("config/lig/config.toml points at the state link's lig.toml", () => {
    expect(readlinkSync(join(repoRoot, "config/lig/config.toml"))).toBe("../../../../state/dots/theme/current/lig.toml");
  });
});

describe("the Ghostty include", () => {
  it("auto points at the state link, four levels up from the repo", () => {
    // The repo is installed at ~/.local/share/dots: four levels up is ~/.local, then state/dots/theme/current.
    expect(readlinkSync(join(repoRoot, "config/ghostty/auto"))).toBe("../../../../state/dots/theme/current");
  });

  it("config.ghostty includes it after its fallback theme", () => {
    const config = readFileSync(join(repoRoot, "config/ghostty/config.ghostty"), "utf8");
    expect(config).toContain("config-file = ?auto/theme.ghostty");
    expect(config.indexOf("config-file = ?auto/theme.ghostty")).toBeGreaterThan(config.indexOf("theme = Catppuccin Mocha"));
  });
});

describe("theme:build", () => {
  it("choices match the theme folders", () => {
    const folders = readdirSync(THEMES, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
      .sort();
    const mise = readFileSync(join(repoRoot, "mise.toml"), "utf8");
    const buildBlock = mise.match(/\[tasks\."theme:build"\][\s\S]*?\nrun =/)?.[0] ?? "";
    expect(choicesIn(buildBlock)).toEqual(folders);
  });
});
