#!/usr/bin/env bun
// The shell theme folders and `mise run theme:build` (docs/THEME.md).
import { describe, expect, it } from "bun:test";
import { existsSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { repoRoot } from "./support/paths";

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
