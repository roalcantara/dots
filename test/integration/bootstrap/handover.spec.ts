#!/usr/bin/env bun
// The bootstrap hooks and the global bootstrap task share `{{ vars.dots_setup }}` (config/mise/conf.d/bootstrap.toml),
// which passes `--profile <name>` for each `mise_env` entry in desktop/dev/container and ignores non-profile
// environments (such as a future `macos` env). This runs the real `mise bootstrap` on a temp config holding the real
// [vars] and hooks; a stub `mise` on PATH records what the hook invokes.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const MISE = Bun.which("mise");
const conf = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as {
  vars: Record<string, unknown>;
  bootstrap: { hooks: Record<string, { run: string }> };
};

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

let t: string;
beforeEach(() => {
  t = realpathSync(mkdtempSync(join(tmpdir(), "handover-")));
  for (const d of ["bin", "cfg/conf.d", "cwd"]) mkdirSync(join(t, d), { recursive: true });
  writeFileSync(join(t, "cfg", "conf.d", "vars.yaml"), readFileSync(join(REPO, "config/mise/conf.d/vars.yaml"), "utf8"));
  const vars = serializeVars(conf.vars);
  writeFileSync(
    join(t, "cfg", "config.toml"),
    [
      "[vars]",
      vars,
      "",
      "[bootstrap.hooks.post-packages]",
      `run = ${JSON.stringify(conf.bootstrap.hooks["post-packages"].run)}`,
      "",
      "[bootstrap.hooks.pre-dotfiles]",
      `run = ${JSON.stringify(conf.bootstrap.hooks["pre-dotfiles"].run)}`,
      "",
    ].join("\n"),
  );
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\nprintf '%s\\n' "$*" > "${join(t, "calls")}"\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function bootstrap(args: string[], only = "dotfiles") {
  const p = Bun.spawnSync([MISE as string, "bootstrap", ...args, "--only", only, "--yes"], {
    cwd: join(t, "cwd"),
    env: {
      HOME: t,
      PATH: `${join(t, "bin")}:/usr/bin:/bin`,
      MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_GLOBAL_CONFIG_FILE: join(t, "cfg", "config.toml"),
      MISE_TRUSTED_CONFIG_PATHS: t,
    },
    stdin: "ignore",
    stdout: "pipe",
    stderr: "pipe",
  });
  expect(p.exitCode, p.stderr.toString()).toBe(0);
  return readFileSync(join(t, "calls"), "utf8").trim();
}

describe.skipIf(!MISE)("bootstrap hand-over", () => {
  it("post-packages calls dots setup --brew --yabai", () => {
    expect(bootstrap([], "packages")).toBe("run dots setup --brew --yabai");
  });

  it("-E container gives --profile container", () => {
    expect(bootstrap(["-E", "container"])).toBe("run dots setup --profile container --app-files");
  });

  it("-E desktop,dev gives both profiles", () => {
    expect(bootstrap(["-E", "desktop,dev"])).toBe("run dots setup --profile desktop --profile dev --app-files");
  });

  it("-E desktop,macos gives only desktop (ignores non-profile envs)", () => {
    expect(bootstrap(["-E", "desktop,macos"])).toBe("run dots setup --profile desktop --app-files");
  });

  it("miserc env reaches the hook", () => {
    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    expect(bootstrap([])).toBe("run dots setup --profile desktop --profile dev --app-files");
  });

  it("no environment gives no --profile (flag default applies)", () => {
    expect(bootstrap([])).toBe("run dots setup --app-files");
  });
});
