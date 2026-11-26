#!/usr/bin/env bun
// docs/BOOTSTRAP.md is the single source on `mise bootstrap`: it documents every bootstrap task, carries the seven
// sections, and the guides that explain bootstrap mechanics link to it.
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const read = (rel: string) => readFileSync(join(REPO, rel), "utf8");
const maybe = Bun.which("mise") ? describe : describe.skip;

function bootstrapTasks(): string[] {
  const p = Bun.spawnSync(["mise", "tasks", "ls", "--json"], {
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

maybe("bootstrap docs", () => {
  it("documents every bootstrap task", () => {
    const doc = read("docs/BOOTSTRAP.md");
    const tasks = bootstrapTasks();
    expect(tasks.length).toBeGreaterThan(20);
    for (const name of tasks) expect(doc, `${name} is documented`).toContain(`\`${name}\``);
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
