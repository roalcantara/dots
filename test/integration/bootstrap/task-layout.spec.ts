#!/usr/bin/env bun
// Repo tasks live next to what they manage, in <folder>/tasks.toml with top-level task names, included by glob from
// the root mise.toml, which declares none itself (docs/superpowers/specs/2026-11-27-mise-task-layout-design.md).
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const toml = (rel: string) => Bun.TOML.parse(readFileSync(join(REPO, rel), "utf8")) as Record<string, unknown>;
const root = toml("mise.toml") as { tasks?: unknown; task_config: { includes: string[] } };
const topicFiles = root.task_config.includes
  .filter((g) => g.endsWith("tasks.toml"))
  .flatMap((g) => [...new Bun.Glob(g).scanSync({ cwd: REPO })])
  .sort();

function listedTasks(): Set<string> {
  const p = Bun.spawnSync(["mise", "tasks", "ls", "--hidden", "--json"], {
    cwd: REPO,
    env: { ...process.env, MISE_TRUSTED_CONFIG_PATHS: REPO },
    stdout: "pipe",
    stderr: "pipe",
  });
  if (p.exitCode !== 0) throw new Error(p.stderr.toString());
  return new Set((JSON.parse(p.stdout.toString()) as { name: string }[]).map((t) => t.name));
}

const maybe = Bun.which("mise") ? describe : describe.skip;

maybe("mise task layout", () => {
  it("the root mise.toml declares no tasks", () => {
    expect(root.tasks).toBeUndefined();
  });

  it("the includes find topic files, never mise's own config folder", () => {
    expect(topicFiles.length).toBeGreaterThan(0);
    expect(topicFiles.filter((f) => f.startsWith("config/mise/"))).toEqual([]);
  });

  it("every topic file uses top-level task tables, and mise loads each of its tasks", () => {
    const listed = listedTasks();
    for (const file of topicFiles) {
      const tasks = toml(file);
      expect(tasks.tasks, `${file} uses top-level names, not [tasks."…"]`).toBeUndefined();
      for (const name of Object.keys(tasks)) expect(listed.has(name), `${file}: ${name}`).toBe(true);
    }
  });
});
