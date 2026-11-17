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
const NAMES = ["catppuccin-mocha", "catppuccin-macchiato"];

// One file per tool, plus the vendored eza theme and its licence.
const FILES = [
  "theme.ghostty",
  "env.zsh",
  "env.bash",
  "ls_colors",
  "eza/theme.yml",
  "eza/LICENSE",
  "zsh-patina.toml",
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

  it("ls_colors is one export line", () => {
    for (const name of NAMES) {
      expect(readFileSync(join(THEMES, name, "ls_colors"), "utf8")).toMatch(/^export LS_COLORS='[^']+'\n$/);
    }
  });

  it.skipIf(!vivid)("theme:build reproduces the committed ls_colors", () => {
    const build = Bun.spawnSync(["mise", "run", "theme:build"], { cwd: repoRoot, stdout: "pipe", stderr: "pipe" });
    expect(build.exitCode).toBe(0);
    const diff = Bun.spawnSync(["git", "diff", "--exit-code", "--", "config/theme"], {
      cwd: repoRoot,
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(diff.exitCode).toBe(0);
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

describe("dots theme", () => {
  let dir = "";
  let link = "";
  let patinaLog = "";

  beforeAll(() => {
    dir = mkdtempSync(join(tmpdir(), "dots-theme-"));
    link = join(dir, "state/dots/theme/current");
    patinaLog = join(dir, "patina.log");
    // A fake zsh-patina: dots theme must restart the daemon so its cached theme does not linger.
    writeFileSync(join(dir, "zsh-patina"), `#!/bin/sh\nprintf '%s\\n' "$*" >> "$DOTS_PATINA_LOG"\n`);
    chmodSync(join(dir, "zsh-patina"), 0o755);
  });
  afterAll(() => rmSync(dir, { recursive: true, force: true }));

  const dots = (args: string[], target = link) =>
    Bun.spawnSync([join(repoRoot, "config/bin/dots"), ...args], {
      env: {
        PATH: `${dir}:${realUsageDir()}:/usr/bin:/bin`,
        HOME: process.env.HOME as string,
        DOTS_THEMES_DIR: THEMES,
        DOTS_THEME_LINK: target,
        DOTS_PATINA_LOG: patinaLog,
      },
      stdout: "pipe",
      stderr: "pipe",
    });

  it("switches the link", () => {
    const r = dots(["theme", "catppuccin-macchiato"]);
    expect(r.exitCode).toBe(0);
    expect(readlinkSync(link).endsWith("/catppuccin-macchiato")).toBe(true);
  });

  it("lists themes and marks the active one", () => {
    const r = dots(["theme"]);
    expect(r.exitCode).toBe(0);
    expect(r.stdout.toString()).toContain("* catppuccin-macchiato");
    expect(r.stdout.toString()).toContain("  catppuccin-mocha");
  });

  it("rejects an unknown name", () => {
    const missing = join(dir, "state/dots/theme/unknown");
    const r = dots(["theme", "nope"], missing);
    expect(r.exitCode).toBe(1);
    expect(r.stderr.toString()).toContain("catppuccin-mocha");
    expect(r.stderr.toString()).toContain("catppuccin-macchiato");
    expect(existsSync(missing)).toBe(false);
  });

  it("restarts zsh-patina", () => {
    writeFileSync(patinaLog, "");
    expect(dots(["theme", "catppuccin-mocha"]).exitCode).toBe(0);
    expect(readFileSync(patinaLog, "utf8").trim().split("\n")).toEqual(["restart"]);
  });

  it("choices match the theme folders", () => {
    const folders = readdirSync(THEMES, { withFileTypes: true })
      .filter((e) => e.isDirectory())
      .map((e) => e.name)
      .sort();
    const source = readFileSync(join(repoRoot, "config/bin/dots"), "utf8");
    const themeBlock = source.match(/#USAGE cmd "theme"[\s\S]*?#USAGE }/)?.[0] ?? "";
    const mise = readFileSync(join(repoRoot, "mise.toml"), "utf8");
    const buildBlock = mise.match(/\[tasks\."theme:build"\][\s\S]*?\nrun =/)?.[0] ?? "";
    expect(choicesIn(themeBlock)).toEqual(folders);
    expect(choicesIn(buildBlock)).toEqual(folders);
  });
});
