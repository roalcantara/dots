#!/usr/bin/env bun
// `mise run setup <desktop|dev>` records the profile in miserc.local.toml and runs the bootstrap with it.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/setup.toml"), "utf8")) as {
  tasks: { setup: { run: string; usage: string } };
}).tasks.setup;

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "setup-task-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, ".local", "share", "dots", "config", "mise"), { recursive: true });
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" > "${join(t, "mise.args")}"\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const run = (profile: string) =>
  Bun.spawnSync(["bash", "-c", task.run], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, usage_profile: profile }, stdout: "pipe", stderr: "pipe",
  });
const miserc = () => readFileSync(join(t, ".local", "share", "dots", "config", "mise", "miserc.local.toml"), "utf8");
const args = () => readFileSync(join(t, "mise.args"), "utf8").trim();

describe("setup task", () => {
  it("accepts only desktop and dev", () => expect(task.usage).toContain('choices "desktop" "dev"'));
  it("dev: records desktop,dev and bootstraps it", () => {
    expect(run("dev").exitCode).toBe(0);
    expect(miserc()).toBe('env = ["desktop", "dev"]\n');
    expect(args()).toBe("bootstrap -E desktop,dev --yes");
  });
  it("desktop: records desktop and bootstraps it", () => {
    expect(run("desktop").exitCode).toBe(0);
    expect(miserc()).toBe('env = ["desktop"]\n');
    expect(args()).toBe("bootstrap -E desktop --yes");
  });
});
