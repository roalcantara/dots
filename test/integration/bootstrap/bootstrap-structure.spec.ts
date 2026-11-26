#!/usr/bin/env bun
// The bootstrap task layout: every step is a described bash file that sources the shared library, and the phase
// file names the five hand-over tasks the hooks will use.
import { describe, expect, it } from "bun:test";
import { readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const STEPS = join(REPO, ".mise/tasks/bootstrap");
const PHASES = [
  "bootstrap:hook:post-packages",
  "bootstrap:hook:pre-dotfiles",
  "bootstrap:hook:post-dotfiles",
  "bootstrap:hook:post-defaults",
  "bootstrap:hook:final",
];

function executable(rel: string): boolean {
  return (statSync(join(STEPS, rel)).mode & 0o111) !== 0;
}

function steps(): string[] {
  const glob = new Bun.Glob("**/*");
  return [...glob.scanSync({ cwd: STEPS, onlyFiles: true })].filter(executable).sort();
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
  const p = Bun.spawnSync(["mise", "tasks", "ls", "--json"], {
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

  it("phases.toml defines exactly the five bootstrap:hook:* tasks, and each run step names an existing task", () => {
    const phases = Bun.TOML.parse(readFileSync(join(STEPS, "phases.toml"), "utf8")) as Record<
      string,
      { run?: unknown }
    >;
    expect(Object.keys(phases).sort()).toEqual([...PHASES].sort());
    const listed = new Set(miseTasks().map((task) => task.name));
    for (const name of PHASES) expect(listed.has(name), `${name} is listed`).toBe(true);
    for (const [name, phase] of Object.entries(phases)) {
      const run = Array.isArray(phase.run) ? phase.run : [];
      for (const step of run) {
        const ref = typeof step === "string" ? step : (step as { task?: string }).task;
        if (ref) expect(listed.has(ref), `${name} step ${ref} exists`).toBe(true);
      }
    }
  });

  // The hooks live only in bootstrap.toml, one per phase, and each is a short hand-over.
  it("each bootstrap hook phase is defined once, in bootstrap.toml, as the hand-over", () => {
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
    expect(Object.keys(found).sort()).toEqual(PHASES.slice(0, 4).map((phase) => phase.replace("bootstrap:hook:", "")).sort());
    for (const [phase, defs] of Object.entries(found)) {
      expect(defs, `${phase} is defined once`).toHaveLength(1);
      expect(defs[0].file, `${phase} lives in bootstrap.toml`).toBe("bootstrap.toml");
      expect(defs[0].run, `${phase} hands over`).toBe(`{{ vars.dots_handover }} bootstrap:hook:${phase}`);
    }
  });

  it("the global bootstrap task is the hand-over to bootstrap:hook:final", () => {
    const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
      tasks: { bootstrap: { run: string } };
    };
    expect(conf.tasks.bootstrap.run).toBe("{{ vars.dots_handover }} bootstrap:hook:final");
  });

  // One shared hand-over (handover.spec.ts runs it through mise). It takes the profile from mise_env and holds no
  // shell $: mise expands $VARS in [vars] at load time, before the hook runs.
  it("the shared hand-over takes the profile from mise_env and holds no shell $", () => {
    const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
      vars: { dots_profile: string; dots_handover: string };
    };
    expect(conf.vars.dots_profile).toContain("mise_env");
    expect(conf.vars.dots_handover).toContain("DOTS_PROFILE={{ vars.dots_profile | quote }}");
    expect(conf.vars.dots_handover).not.toContain("$");
  });

  it('no "# <name>: begin" marker remains in config/mise/conf.d', () => {
    const dir = join(REPO, "config/mise/conf.d");
    for (const file of [...new Bun.Glob("*.toml").scanSync({ cwd: dir })] as string[]) {
      expect(readFileSync(join(dir, file), "utf8"), file).not.toMatch(/^# [a-z-]+: begin$/m);
    }
  });
});
