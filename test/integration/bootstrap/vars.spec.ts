#!/usr/bin/env bun
// Hard-coded bootstrap values live in config/mise/conf.d/vars.yaml, read into {{ vars.* }} by bootstrap.toml
// without exporting them to the environment. Because mise settings cannot read `vars`, config/mise/config.toml
// mirrors the location in `dotfiles.root = "{{ xdg_data_home }}/dots"`; this spec verifies they agree.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, readdirSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const VARS_YAML_PATH = join(REPO, "config/mise/conf.d/vars.yaml");
const BOOTSTRAP_TOML_PATH = join(REPO, "config/mise/conf.d/bootstrap.toml");
const GLOBAL_CONFIG_PATH = join(REPO, "config/mise/config.toml");

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "dots-vars-")));
  mkdirSync(join(t, "cfg", "conf.d"), { recursive: true });
  mkdirSync(join(t, "cwd"), { recursive: true });
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function readVarsSection(): Record<string, unknown> {
  const parsed = Bun.TOML.parse(readFileSync(BOOTSTRAP_TOML_PATH, "utf8")) as {
    vars?: Record<string, unknown>;
  };
  return parsed.vars ?? {};
}

function serializeVars(vars: Record<string, unknown>): string {
  const lines: string[] = [];
  for (const [k, v] of Object.entries(vars)) {
    if (v && typeof v === "object" && !Array.isArray(v)) {
      for (const [sk, sv] of Object.entries(v as Record<string, unknown>)) {
        lines.push(`${k}.${sk} = ${JSON.stringify(sv)}`);
      }
    } else {
      lines.push(`${k} = ${JSON.stringify(v)}`);
    }
  }
  return lines.join("\n");
}

function readDotsDir(yamlPath = VARS_YAML_PATH): string {
  const raw = readFileSync(yamlPath, "utf8");
  const match = raw.match(/^\s*dots_dir:\s*([^\s#]+)/m);
  if (!match) throw new Error(`dots_dir not found in ${yamlPath}`);
  return match[1].replace(/^['"]|['"]$/g, "");
}

function resolveDotfilesRoot(configPath: string, homeDir: string): string {
  const cfgDir = join(t, "root-check");
  mkdirSync(cfgDir, { recursive: true });
  writeFileSync(join(cfgDir, "config.toml"), readFileSync(configPath, "utf8"));
  const p = Bun.spawnSync([MISE as string, "settings", "get", "dotfiles.root"], {
    cwd: join(t, "cwd"),
    env: {
      HOME: homeDir,
      PATH: process.env.PATH ?? "/usr/bin:/bin",
      MISE_CONFIG_DIR: cfgDir,
      MISE_TRUSTED_CONFIG_PATHS: homeDir,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(p.exitCode, p.stderr.toString()).toBe(0);
  return p.stdout.toString().trim();
}

function renderDotsVar(varsYamlContent: string): { dots: string; exported: string } {
  const varsToml = serializeVars(readVarsSection());
  writeFileSync(join(t, "cfg", "config.toml"), "");
  writeFileSync(join(t, "cfg", "conf.d", "vars.yaml"), varsYamlContent);
  writeFileSync(
    join(t, "cfg", "conf.d", "bootstrap.toml"),
    `[vars]\n${varsToml}\n\n[tasks.probe]\nrun = 'printf "%s\\n%s\\n" "{{ vars.dots }}" "\${dots_dir:-UNSET}"'\n`,
  );
  const p = Bun.spawnSync([MISE as string, "run", "-q", "probe"], {
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
  const [dots, exported] = p.stdout.toString().trim().split("\n");
  return { dots, exported };
}

describe.skipIf(!MISE)("conf.d/vars.yaml and dots location", () => {
  it("vars.dots renders $HOME plus dots_dir without exporting dots_dir", () => {
    const yaml = readFileSync(VARS_YAML_PATH, "utf8");
    const dotsDir = readDotsDir();
    const result = renderDotsVar(yaml);
    expect(result.dots).toBe(join(t, dotsDir));
    expect(result.exported).toBe("UNSET");
  });

  it("vars.dots follows a changed dots_dir", () => {
    const result = renderDotsVar("dots_dir: src/dots\n");
    expect(result.dots).toBe(join(t, "src/dots"));
    expect(result.exported).toBe("UNSET");
  });

  it("dotfiles.root and vars.dots agree for the default XDG layout", () => {
    const dotsDir = readDotsDir();
    const resolvedRoot = resolveDotfilesRoot(GLOBAL_CONFIG_PATH, t);
    expect(resolvedRoot).toBe(join(t, dotsDir));

    // Changing only vars.yaml makes the agreement fail.
    const altYaml = join(t, "alt-vars.yaml");
    writeFileSync(altYaml, "dots_dir: src/dots\n");
    expect(resolvedRoot).not.toBe(join(t, readDotsDir(altYaml)));

    // Changing only dotfiles.root makes the agreement fail.
    const altCfg = join(t, "alt-config.toml");
    writeFileSync(
      altCfg,
      readFileSync(GLOBAL_CONFIG_PATH, "utf8").replace('dotfiles.root = "{{ xdg_data_home }}/dots"', 'dotfiles.root = "{{ xdg_data_home }}/other"'),
    );
    expect(resolveDotfilesRoot(altCfg, t)).not.toBe(join(t, dotsDir));
  });

  it("no literal .local/share/dots remains in config/mise/conf.d/*.toml or config/mise/config.toml outside allowed entries", () => {
    const ALLOWED_PLAIN_DOTFILE_TARGETS = new Set([
      "~/.config/kb",
      "~/.zshenv",
      "~/.bashrc",
      "~/.profile",
      "~/.claude/settings.json",
      "~/.claude/agents",
      "~/.local/bin",
      "~/.local/state/skills/.skill-lock.json",
      "~/.agents/.skill-lock.json",
      "~/.agents/commands",
      "~/.claude/commands",
      "vscode-settings",
      "vscode-keybindings",
    ]);

    // Check config/mise/config.toml: only trusted_config_paths (which mise does not template-expand) may carry it.
    const globalCfg = Bun.TOML.parse(readFileSync(GLOBAL_CONFIG_PATH, "utf8")) as {
      settings?: Record<string, unknown>;
    };
    const settingsCopy = { ...(globalCfg.settings ?? {}) };
    delete settingsCopy.trusted_config_paths;
    expect(JSON.stringify(settingsCopy)).not.toContain(".local/share/dots");

    // Check every conf.d/*.toml file (backup.toml is deleted in Task 6).
    const confDir = join(REPO, "config/mise/conf.d");
    for (const file of readdirSync(confDir).filter((f) => f.endsWith(".toml") && f !== "backup.toml")) {
      const fullPath = join(confDir, file);
      if (file === "dotfiles.toml") {
        const parsed = Bun.TOML.parse(readFileSync(fullPath, "utf8")) as {
          dotfiles?: Record<string, { source?: string }>;
          dotfile_groups?: Record<string, unknown>;
        };
        expect(JSON.stringify(parsed.dotfile_groups ?? {})).not.toContain(".local/share/dots");
        const found = Object.entries(parsed.dotfiles ?? {})
          .filter(([, entry]) => typeof entry.source === "string" && entry.source.includes(".local/share/dots"))
          .map(([target]) => target)
          .sort();
        expect(found).toEqual([...ALLOWED_PLAIN_DOTFILE_TARGETS].sort());
      } else {
        const nonCommentLines = readFileSync(fullPath, "utf8")
          .split("\n")
          .filter((l) => !l.trimStart().startsWith("#"))
          .join("\n");
        expect(nonCommentLines, `${file} still contains literal .local/share/dots`).not.toContain(".local/share/dots");
      }
    }
  });
});
