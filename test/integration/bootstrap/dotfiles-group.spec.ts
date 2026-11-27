#!/usr/bin/env bun
// config/mise/conf.d/dotfiles.toml declares all ~/.config/<same-name> links as [dotfile_groups.config]
// so they inherit dotfiles.root instead of repeating ~/.local/share/dots. Plain [dotfiles] entries
// remain for targets outside ~/.config/<same-name>.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const DOTFILES_TOML = join(REPO, "config/mise/conf.d/dotfiles.toml");

type DotfileGroup = {
  root?: string;
  target?: string;
  mode?: string;
  relative?: boolean;
  exclude?: string[];
  entries?: Record<string, { mode?: string }>;
};

type ParsedDotfiles = {
  dotfile_groups?: Record<string, DotfileGroup>;
  dotfiles?: Record<string, Record<string, unknown>>;
};

function parseDotfiles(): ParsedDotfiles {
  return Bun.TOML.parse(readFileSync(DOTFILES_TOML, "utf8")) as ParsedDotfiles;
}

const EXPECTED_GROUP_NAMES = [
  ".markdownlint.yml",
  ".profile",
  "age",
  "atlassian",
  "bash",
  "bat",
  "borders",
  "bin",
  "claude",
  "dinky",
  "dots",
  "dprint",
  "duti",
  "fabric",
  "fnox",
  "gh",
  "ghostty",
  "git",
  "github",
  "gopass",
  "gortex",
  "helix",
  "homebrew",
  "karabiner",
  "kodexb",
  "lig",
  "npm",
  "nvim",
  "posting",
  "ripgrep",
  "snippets",
  "sops",
  "swiftbar",
  "television",
  "theme",
  "tombi",
  "vscode",
  "wakatime",
  "yabai",
  "zed",
  "zentty",
  "zsh",
  "zsh-patina",
];

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "dots-group-")));
  mkdirSync(join(t, "cfg", "conf.d"), { recursive: true });
  mkdirSync(join(t, "cwd"), { recursive: true });
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

describe("conf.d/dotfiles.toml dotfile group", () => {
  it("every ~/.config/<name> link comes from [dotfile_groups.config]", () => {
    const parsed = parseDotfiles();
    const group = parsed.dotfile_groups?.config;
    expect(group).toBeDefined();
    expect(group?.root).toBe("config");
    expect(group?.target).toBe("~/.config");
    expect(group?.mode).toBe("symlink-each");
    expect(group?.relative).toBe(true);

    const entries = group?.entries ?? {};
    const expectedTargets = EXPECTED_GROUP_NAMES.map((n) => `~/.config/${n}`).sort();
    expect(Object.keys(entries).sort()).toEqual(expectedTargets);
    for (const target of expectedTargets) {
      expect(entries[target]?.mode).toBe("symlink");
    }
  });

  it.skipIf(!MISE)("the group links only its declared entries and nothing else", () => {
    const parsed = parseDotfiles();
    const group = parsed.dotfile_groups?.config;
    expect(group?.exclude).toContain("*");
    expect(group?.exclude).toContain(".*");

    // Verify with real mise dot apply on a temp checkout containing declared + undeclared entries.
    const cfgSrc = join(t, ".local/share/dots/config");
    mkdirSync(join(cfgSrc, "age"), { recursive: true });
    mkdirSync(join(cfgSrc, "unlinked-dir"), { recursive: true });
    mkdirSync(join(cfgSrc, ".vscode"), { recursive: true });
    mkdirSync(join(t, ".config"), { recursive: true });
    writeFileSync(join(cfgSrc, "age", "a"), "ok");
    writeFileSync(join(cfgSrc, "unlinked-dir", "u"), "no");
    writeFileSync(join(cfgSrc, ".vscode", "s.json"), "{}");
    writeFileSync(join(cfgSrc, ".gitignore"), "*.env\n");

    writeFileSync(
      join(t, "cfg", "config.toml"),
      '[settings]\ndotfiles.root = "{{ xdg_data_home }}/dots"\ndotfiles.relative_symlinks = true\n',
    );
    writeFileSync(
      join(t, "cfg", "conf.d", "dotfiles.toml"),
      [
        "[dotfile_groups.config]",
        `root = ${JSON.stringify(group?.root)}`,
        `target = ${JSON.stringify(group?.target)}`,
        `mode = ${JSON.stringify(group?.mode)}`,
        `relative = ${String(group?.relative)}`,
        `exclude = ${JSON.stringify(group?.exclude)}`,
        "[dotfile_groups.config.entries]",
        '"~/.config/age" = { mode = "symlink" }',
        "",
      ].join("\n"),
    );

    const p = Bun.spawnSync([MISE as string, "dot", "apply", "--yes"], {
      cwd: join(t, "cwd"),
      env: {
        HOME: t,
        PATH: process.env.PATH ?? "/usr/bin:/bin",
        MISE_CONFIG_DIR: join(t, "cfg"),
        MISE_TRUSTED_CONFIG_PATHS: t,
      },
      stdin: "ignore",
      stdout: "pipe",
      stderr: "pipe",
    });
    expect(p.exitCode, p.stderr.toString()).toBe(0);
    expect(lstatSync(join(t, ".config/age")).isSymbolicLink()).toBe(true);
    expect(readlinkSync(join(t, ".config/age"))).toBe("../.local/share/dots/config/age");
    expect(existsSync(join(t, ".config/unlinked-dir"))).toBe(false);
    expect(existsSync(join(t, ".config/.vscode"))).toBe(false);
    expect(existsSync(join(t, ".config/.gitignore"))).toBe(false);
  });

  it("plain [dotfiles] entries outside ~/.config/<same-name> keep their targets and modes", () => {
    const parsed = parseDotfiles();
    const df = parsed.dotfiles ?? {};

    const expectedPlainTargets = [
      "~/.config/kb",
      "~/.zshenv",
      "~/.bashrc",
      "~/.profile",
      "~/.claude/settings.json",
      "~/.claude/agents",
      "~/.ssh",
      "~/.gnupg",
      "~/.local/bin",
      "~/.local/state/skills/.skill-lock.json",
      "~/.agents/.skill-lock.json",
      "~/.agents/commands",
      "~/.claude/commands",
      "vscode-settings",
      "vscode-keybindings",
      "vscode-snippets",
      "claude-skills",
    ].sort();

    expect(Object.keys(df).sort()).toEqual(expectedPlainTargets);
    expect(df["~/.config/kb"]?.source).toBe("~/.local/share/dots/config/kodexb");
    expect(df["~/.local/bin"]?.mode).toBe("symlink-each");
    expect(df["~/.ssh"]?.source).toBe("~/.config/ssh");
    expect(df["~/.gnupg"]?.source).toBe("~/.config/gnupg");
    expect(Array.isArray(df["vscode-settings"]?.variants)).toBe(true);
    expect(Array.isArray(df["vscode-keybindings"]?.variants)).toBe(true);
    expect(Array.isArray(df["vscode-snippets"]?.variants)).toBe(true);
    expect(Array.isArray(df["claude-skills"]?.variants)).toBe(true);
  });
});
