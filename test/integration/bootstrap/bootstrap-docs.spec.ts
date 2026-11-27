#!/usr/bin/env bun
// docs/BOOTSTRAP.md is the single source on `mise bootstrap` and the `mise run dots` front door:
// it documents every bootstrap task, subcommand, part flag, and conf.d file, carries the seven sections,
// and no doc outside docs/blog/posts and docs/superpowers keeps the retired command names.
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (rel: string) => readFileSync(join(REPO, rel), "utf8");
const maybe = Bun.which("mise") ? describe : describe.skip;

function bootstrapTasks(): string[] {
  const p = Bun.spawnSync(["mise", "tasks", "ls", "--hidden", "--json"], {
    cwd: REPO,
    env: { ...process.env, MISE_TRUSTED_CONFIG_PATHS: REPO },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  if (p.exitCode !== 0) throw new Error(p.stderr.toString());
  return (JSON.parse(p.stdout.toString()) as { name: string }[])
    .map((task) => task.name)
    .filter((name) => name === "bootstrap" || name.startsWith("bootstrap:"));
}

function setupPartFlags(): string[] {
  const tasksToml = Bun.TOML.parse(read("config/mise/conf.d/tasks.toml")) as {
    tasks: { dots: { usage: string } };
  };
  const setupBlock = tasksToml.tasks.dots.usage.split('cmd "backup"')[0] ?? "";
  const flags: string[] = [];
  for (const m of setupBlock.matchAll(/flag\s+"(--[a-z-]+)"/g)) {
    const f = m[1];
    if (f && f !== "--dry-run" && f !== "--no-remind") flags.push(f);
  }
  return flags;
}

maybe("bootstrap docs", () => {
  it("documents every bootstrap task", () => {
    const doc = read("docs/BOOTSTRAP.md");
    const tasks = bootstrapTasks();
    expect(tasks.length).toBeGreaterThan(20);
    for (const name of tasks) expect(doc, `${name} is documented`).toContain(`\`${name}\``);
  });

  it("BOOTSTRAP.md documents mise run dots and each subcommand and part flag", () => {
    const doc = read("docs/BOOTSTRAP.md");
    expect(doc).toContain("mise run dots");
    for (const sub of ["setup", "backup", "profile"]) {
      expect(doc, `subcommand ${sub}`).toContain(`dots ${sub}`);
    }
    const flags = setupPartFlags();
    expect(flags.length).toBe(16);
    for (const flag of flags) {
      expect(doc, `part flag ${flag}`).toContain(`\`${flag}\``);
    }
  });

  it("conf.d is described as six files with one job each", () => {
    const doc = read("docs/BOOTSTRAP.md");
    for (const file of ["bootstrap.toml", "dotfiles.toml", "macos.toml", "system.toml", "tasks.toml", "vars.yaml"]) {
      expect(doc, `conf.d/${file}`).toContain(file);
    }
    expect(doc).not.toContain("yabai.toml");
    expect(doc).not.toContain("setup.toml");
    expect(doc).not.toContain("conf.d/backup.toml");
  });

  it("no doc outside docs/blog/posts and docs/superpowers mentions retired commands", () => {
    const retired = /bootstrap:hook:|mise run setup(?!:)|\breinstall:audit\b|\bbackup:(?:init|restore|snapshots|forget)\b/;
    const docs = [
      "README.md",
      "AGENTS.md",
      ...[...new Bun.Glob("docs/**/*.md").scanSync({ cwd: REPO })]
        .filter((f) => !f.startsWith("docs/blog/posts/") && !f.startsWith("docs/superpowers/")),
      ...[...new Bun.Glob("config/**/README.md").scanSync({ cwd: REPO })]
        .filter((f) => f !== "config/bin/README.md"),
    ];
    for (const rel of docs) {
      const content = read(rel);
      expect(retired.test(content), `${rel} still mentions a retired command: ${content.match(retired)?.[0]}`).toBe(false);
    }
  });

  it("the guides link to it", () => {
    for (const file of ["README.md", "docs/MACOS.md", "docs/REINSTALL.md", "docs/TILING.md", "docs/DOCKER.md", "AGENTS.md"]) {
      expect(read(file), `${file} links docs/BOOTSTRAP.md`).toContain("BOOTSTRAP.md");
    }
  });

  it("has the seven sections", () => {
    const doc = read("docs/BOOTSTRAP.md");
    for (const heading of ["Overview", "Rationale", "Profiles", "Steps", "Recipes", "Gotchas", "Troubleshooting"]) {
      expect(doc, `## ${heading}`).toContain(`## ${heading}`);
    }
  });
});
