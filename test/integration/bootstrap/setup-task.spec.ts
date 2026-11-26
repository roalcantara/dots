#!/usr/bin/env bun
// `mise run setup <desktop|dev>` runs the bootstrap with that profile and `--save-env`, which records it in
// miserc.local.toml so later runs and new shells use it.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/setup.toml"), "utf8")) as {
  tasks: { setup: { run: string; usage: string } };
}).tasks.setup;

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "setup-task-")));
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
const args = () => readFileSync(join(t, "mise.args"), "utf8").trim();

describe("setup task", () => {
  it("accepts only desktop and dev", () => expect(task.usage).toContain('choices "desktop" "dev"'));
  it("dev: bootstraps desktop,dev and saves it", () => {
    expect(run("dev").exitCode).toBe(0);
    expect(args()).toBe("bootstrap -E desktop,dev --save-env --yes");
  });
  it("desktop: bootstraps desktop and saves it", () => {
    expect(run("desktop").exitCode).toBe(0);
    expect(args()).toBe("bootstrap -E desktop --save-env --yes");
  });
  it("writes no miserc itself: mise does", () => {
    run("dev");
    expect(existsSync(join(t, ".local", "share", "dots", "config", "mise", "miserc.local.toml"))).toBe(false);
  });
});

// The real mise on an empty temp config: --save-env records the profile, keeps the file's other keys, and does so
// even when the run fails, as the task's old printf did before bootstrapping.
describe.skipIf(!MISE)("mise bootstrap --save-env", () => {
  const save = (hook: string) => {
    mkdirSync(join(t, "cfg"));
    mkdirSync(join(t, "cwd"));
    writeFileSync(join(t, "cfg", "config.toml"), `[bootstrap.hooks.pre-dotfiles]\nrun = ${JSON.stringify(hook)}\n`);
    writeFileSync(join(t, "cfg", "miserc.local.toml"), '# kept\nenv = ["desktop"]\n');
    Bun.spawnSync([MISE as string, "bootstrap", "-E", "desktop,dev", "--save-env", "--only", "dotfiles", "--yes"], {
      cwd: join(t, "cwd"),
      env: {
        HOME: t, PATH: "/usr/bin:/bin", MISE_CONFIG_DIR: join(t, "cfg"),
        MISE_GLOBAL_CONFIG_FILE: join(t, "cfg", "config.toml"), MISE_TRUSTED_CONFIG_PATHS: t,
      },
      stdin: "ignore", stdout: "pipe", stderr: "pipe",
    });
    return readFileSync(join(t, "cfg", "miserc.local.toml"), "utf8");
  };

  it("records the environments and keeps the file's other lines", () => {
    const miserc = save("true");
    expect(miserc).toContain('env = ["desktop", "dev"]');
    expect(miserc).toContain("# kept");
  });

  it("records them even when the bootstrap fails", () => {
    expect(save("exit 3")).toContain('env = ["desktop", "dev"]');
  });
});
