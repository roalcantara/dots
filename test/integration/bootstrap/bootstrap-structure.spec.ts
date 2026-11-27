#!/usr/bin/env bun
// The bootstrap task layout: every step is a hidden bash file extending bootstrap_step, parts.toml defines
// one hidden dots:setup:<part> task per part plus remind covering every step once, and bootstrap.toml's
// hooks and global bootstrap task call `{{ vars.dots_setup }}` with their phase's parts (arguments, in order).
import { describe, expect, it } from "bun:test";
import { readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

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

  it("parts.toml defines exactly one task per part plus remind, all hidden, and every step belongs to exactly one part", () => {
    const parts = Bun.TOML.parse(readFileSync(join(STEPS, "parts.toml"), "utf8")) as Record<
      string,
      { hide?: boolean; description?: string; run?: { task?: string }[] }
    >;
    const expectedParts = [...PARTS, "remind"].map((p) => `dots:setup:${p}`).sort();
    expect(Object.keys(parts).sort()).toEqual(expectedParts);

    const listed = new Set(miseTasks().map((task) => task.name));
    const seenSteps: string[] = [];
    for (const [name, part] of Object.entries(parts)) {
      expect(part.hide, `${name} hide`).toBe(true);
      expect(part.description, `${name} description`).toBeTruthy();
      expect(listed.has(name), `${name} is registered`).toBe(true);
      for (const step of part.run ?? []) {
        if (step.task) {
          expect(listed.has(step.task), `${name} step ${step.task} exists`).toBe(true);
          seenSteps.push(step.task);
        }
      }
    }
    const allStepNames = steps().map(stepTaskName).sort();
    expect(seenSteps.sort()).toEqual(allStepNames);
  });

  it("dots setup's Tab list and its run order name every part once, in order, with its parts.toml help", () => {
    const parts = Bun.TOML.parse(readFileSync(join(STEPS, "parts.toml"), "utf8")) as Record<string, { description: string }>;
    const dots = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/tasks.toml"), "utf8")) as {
      tasks: { dots: { usage: string; run: string } };
    }).tasks.dots;
    const setup = dots.usage.split('cmd "backup"')[0] ?? "";
    // Each `complete` line is 'name:help', with a quote written as '"'"'.
    const listed = [...setup.matchAll(/^\s*'([a-z-]+):(.*)'(?: \\)?$/gm)].map((m) => [m[1], m[2].replaceAll(`'"'"'`, "'")]);
    expect(listed.map(([name]) => name)).toEqual(PARTS);
    for (const [name, help] of listed) {
      const want = parts[`dots:setup:${name}`].description;
      expect(help, `${name} help`).toBe(want);
    }
    expect(dots.run).toContain(`all_parts=(${PARTS.join(" ")})`);
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
    const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
      tasks: { bootstrap: { run: string } };
    };
    expect(conf.tasks.bootstrap.run).toBe(`{{ vars.dots_setup }} ${FINAL_PARTS}`);
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
