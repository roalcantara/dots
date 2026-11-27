#!/usr/bin/env bun
// `mise run dots profile <desktop|dev>` runs `mise bootstrap -E <list> --save-env --yes`, which records
// the chosen profile in miserc.local.toml so later runs and new shells use it.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const TASKS_TOML = join(REPO, "config/mise/conf.d/tasks.toml");

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "dots-profile-")));
  mkdirSync(join(t, "bin"), { recursive: true });
  mkdirSync(join(t, "cfg", "conf.d"), { recursive: true });
  mkdirSync(join(t, "cwd"), { recursive: true });
  mkdirSync(join(t, ".local", "share", "dots", "config", "mise"), { recursive: true });

  writeFileSync(join(t, "cfg", "config.toml"), "");
  writeFileSync(join(t, "cfg", "conf.d", "vars.yaml"), "dots_dir: .local/share/dots\n");
  writeFileSync(
    join(t, "cfg", "conf.d", "bootstrap.toml"),
    '[vars]\n_.file = "{{ mise_config_dir }}/conf.d/vars.yaml"\ndots = "{{ env.HOME }}/{{ vars.dots_dir }}"\n',
  );
  writeFileSync(join(t, "cfg", "conf.d", "tasks.toml"), readFileSync(TASKS_TOML, "utf8"));
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\necho "$@" > "${join(t, "mise.args")}"\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function runProfile(profile: string) {
  return Bun.spawnSync([MISE as string, "run", "-q", "dots", "profile", profile], {
    cwd: join(t, "cwd"),
    env: {
      HOME: t,
      PATH: `${join(t, "bin")}:/usr/bin:/bin`,
      MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_TRUSTED_CONFIG_PATHS: t,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
}
const args = () => readFileSync(join(t, "mise.args"), "utf8").trim();

describe.skipIf(!MISE)("mise run dots profile", () => {
  it("accepts only desktop and dev", () => {
    const r = runProfile("container");
    expect(r.exitCode).not.toBe(0);
    expect(existsSync(join(t, "mise.args"))).toBe(false);
  });

  it("dev: bootstraps desktop,dev and saves it", () => {
    const r = runProfile("dev");
    expect(r.exitCode, r.stderr.toString()).toBe(0);
    expect(args()).toBe("bootstrap -E desktop,dev --save-env --yes");
  });

  it("desktop: bootstraps desktop and saves it", () => {
    const r = runProfile("desktop");
    expect(r.exitCode, r.stderr.toString()).toBe(0);
    expect(args()).toBe("bootstrap -E desktop --save-env --yes");
  });

  it("writes no miserc itself: mise does", () => {
    runProfile("dev");
    expect(existsSync(join(t, ".local", "share", "dots", "config", "mise", "miserc.local.toml"))).toBe(false);
  });
});

// The real mise on an empty temp config: --save-env records the profile, keeps the file's other keys, and does so
// even when the run fails.
describe.skipIf(!MISE)("mise bootstrap --save-env", () => {
  const save = (hook: string) => {
    const cfg = join(t, "save-cfg");
    mkdirSync(cfg, { recursive: true });
    writeFileSync(join(cfg, "config.toml"), `[bootstrap.hooks.pre-dotfiles]\nrun = ${JSON.stringify(hook)}\n`);
    writeFileSync(join(cfg, "miserc.local.toml"), '# kept\nenv = ["desktop"]\n');
    Bun.spawnSync([MISE as string, "bootstrap", "-E", "desktop,dev", "--save-env", "--only", "dotfiles", "--yes"], {
      cwd: join(t, "cwd"),
      env: {
        HOME: t,
        PATH: "/usr/bin:/bin",
        MISE_CONFIG_DIR: cfg,
        MISE_GLOBAL_CONFIG_FILE: join(cfg, "config.toml"),
        MISE_TRUSTED_CONFIG_PATHS: t,
      },
      stdin: "ignore",
      stdout: "pipe",
      stderr: "pipe",
    });
    return readFileSync(join(cfg, "miserc.local.toml"), "utf8");
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
