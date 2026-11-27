#!/usr/bin/env bun
// The bootstrap task layout: every step is a hidden bash file extending bootstrap_step, tasks.toml's
// vars.dots_setup_parts names each part and its steps, covering every step once, and bootstrap.toml's hooks and
// tasks.toml's bootstrap task call `{{ vars.dots_setup }}` with their phase's parts (arguments, in order).
import { describe, expect, it } from "bun:test";
import { readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { parts, tasksToml } from "./parts";

const REPO = join(import.meta.dir, "../../..");
const STEPS = join(REPO, ".mise/tasks/bootstrap");

const PARTS = [
  "brew",
  "yabai",
  "app-files",
  "vscode",
  "bat",
  "lig",
  "macos",
  "swiftbar",
  "git",
  "shell",
  "dev",
  "secrets",
  "tiling",
  "ai",
  "skills",
  "nvim",
];

const HOOK_PARTS: Record<string, string> = {
  "post-packages": "brew yabai",
  "pre-dotfiles": "app-files",
  "post-dotfiles": "vscode bat lig",
  "post-defaults": "macos swiftbar",
};

const FINAL_PARTS = "git shell dev secrets tiling ai skills nvim";

function executable(rel: string): boolean {
  return (statSync(join(STEPS, rel)).mode & 0o111) !== 0;
}

function steps(): string[] {
  const glob = new Bun.Glob("**/*");
  return [...glob.scanSync({ cwd: STEPS, onlyFiles: true })].filter(executable).sort();
}

function stepTaskName(rel: string): string {
  return `bootstrap:${rel.replace(/\.sh$/, "").replaceAll("/", ":")}`;
}

function header(rel: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const line of readFileSync(join(STEPS, rel), "utf8").split("\n")) {
    const match = /^#MISE\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/.exec(line);
    if (match) out[match[1]] = match[2];
  }
  return out;
}

function miseTasks(): { name: string }[] {
  const p = Bun.spawnSync(["mise", "tasks", "ls", "--hidden", "--json"], {
    cwd: REPO,
    env: { ...process.env, MISE_TRUSTED_CONFIG_PATHS: REPO },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  if (p.exitCode !== 0) throw new Error(p.stderr.toString());
  return JSON.parse(p.stdout.toString()) as { name: string }[];
}

const maybe = Bun.which("mise") ? describe : describe.skip;

maybe("bootstrap task structure", () => {
  it("every executable under .mise/tasks/bootstrap has a description and a bash shebang", () => {
    for (const rel of steps()) {
      const text = readFileSync(join(STEPS, rel), "utf8");
      expect(text.startsWith("#!/usr/bin/env bash\n"), `${relative(STEPS, join(STEPS, rel))} shebang`).toBe(true);
      expect(header(rel).description, `${relative(STEPS, join(STEPS, rel))} description`).toBeTruthy();
    }
  });

  it("every step sources _lib.sh", () => {
    for (const rel of steps()) {
      expect(readFileSync(join(STEPS, rel), "utf8"), `${relative(STEPS, join(STEPS, rel))} sources _lib.sh`).toContain(
        '. "${BASH_SOURCE%/*}/../_lib.sh"',
      );
    }
  });

  it("every step is hidden and uses the shared --profile definition", () => {
    for (const rel of steps()) {
      const h = header(rel);
      expect(h.hide, `${relative(STEPS, join(STEPS, rel))} hide`).toBe("true");
      expect(h.extends, `${relative(STEPS, join(STEPS, rel))} extends`).toBe('"bootstrap_step"');
    }
  });

  it("vars.dots_setup_parts names each part once, in order, with a help, and every step belongs to exactly one part", () => {
    const listed = new Set(miseTasks().map((task) => task.name));
    expect(parts().map((p) => p.name)).toEqual(PARTS);
    const seenSteps: string[] = [];
    for (const part of parts()) {
      expect(part.help, `${part.name} help`).toBeTruthy();
      for (const step of part.steps) {
        expect(listed.has(step), `${part.name} step ${step} exists`).toBe(true);
        seenSteps.push(step);
      }
    }
    // Every step file runs in exactly one part, except the Brewfile reminder, which dots setup runs last.
    expect([...seenSteps, "bootstrap:brew:remind"].sort()).toEqual(steps().map(stepTaskName).sort());
  });

  it("dots setup renders its Tab list and its run order from vars.dots_setup_parts", () => {
    const dots = tasksToml().tasks.dots;
    expect(dots.usage).toContain("vars.dots_setup_parts");
    expect(dots.run).toContain("vars.dots_setup_parts");
    expect(dots.usage).not.toMatch(/^\s*'brew:/m);
  });

  it("each hook is {{ vars.dots_setup }} --no-remind plus exactly its phase's parts", () => {
    const dir = join(REPO, "config/mise/conf.d");
    const found: Record<string, { file: string; run: string }[]> = {};
    for (const file of [...new Bun.Glob("*.toml").scanSync({ cwd: dir })] as string[]) {
      const conf = Bun.TOML.parse(readFileSync(join(dir, file), "utf8")) as {
        bootstrap?: { hooks?: Record<string, { run?: string }> };
      };
      for (const [phase, hook] of Object.entries(conf.bootstrap?.hooks ?? {})) {
        (found[phase] ??= []).push({ file, run: hook.run ?? "" });
      }
    }
    expect(Object.keys(found).sort()).toEqual(Object.keys(HOOK_PARTS).sort());
    for (const [phase, defs] of Object.entries(found)) {
      expect(defs, `${phase} is defined once`).toHaveLength(1);
      expect(defs[0].file, `${phase} lives in bootstrap.toml`).toBe("bootstrap.toml");
      expect(defs[0].run, `${phase} hands over`).toBe(`{{ vars.dots_setup }} --no-remind ${HOOK_PARTS[phase]}`);
    }
  });

  it("[tasks.bootstrap] carries the final parts", () => {
    expect(tasksToml().tasks.bootstrap.run).toBe(`{{ vars.dots_setup }} ${FINAL_PARTS}`);
  });

  it("dots_setup takes profiles from mise_env and holds no shell $", () => {
    const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
      vars: { dots_profiles: string; dots_setup: string };
    };
    expect(conf.vars.dots_profiles).toContain("mise_env");
    expect(conf.vars.dots_setup).toContain("mise run dots setup");
    expect(conf.vars.dots_setup).not.toContain("$");
  });

  it('no "# <name>: begin" marker remains in config/mise/conf.d', () => {
    const dir = join(REPO, "config/mise/conf.d");
    for (const file of [...new Bun.Glob("*.toml").scanSync({ cwd: dir })] as string[]) {
      expect(readFileSync(join(dir, file), "utf8"), file).not.toMatch(/^# [a-z-]+: begin$/m);
    }
  });
});
