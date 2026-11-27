#!/usr/bin/env bun
// The bootstrap hooks and the bootstrap task share one hand-over, `{{ vars.dots_handover }} bootstrap:hook:<phase>`
// (config/mise/conf.d/bootstrap.toml). Hooks get neither [env] nor MISE_ENV, so the hand-over takes the profile from
// mise's `mise_env` template variable. This runs the real `mise bootstrap` on a temp config holding the real [vars] and
// one hook; a stub `mise` on PATH records what the hand-over would run.
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
  // Only the vars and one hook: the rest of bootstrap.toml would install packages.
  const vars = serializeVars(conf.vars);
  writeFileSync(join(t, "cfg", "config.toml"), `[vars]\n${vars}\n\n[bootstrap.hooks.pre-dotfiles]\nrun = ${JSON.stringify(conf.bootstrap.hooks["pre-dotfiles"].run)}\n`);
  writeFileSync(join(t, "bin", "mise"), `#!/bin/sh\nprintf '%s\\n' "$*" "\${DOTS_PROFILE:-<unset>}" > "${join(t, "calls")}"\n`);
  chmodSync(join(t, "bin", "mise"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

// The real mise runs the hook; inside it, `mise` resolves to the stub. PATH has no brew and no Bun (Review Focus 1).
function bootstrap(args: string[]) {
  const p = Bun.spawnSync([MISE as string, "bootstrap", ...args, "--only", "dotfiles", "--yes"], {
    cwd: join(t, "cwd"),
    env: {
      HOME: t, PATH: `${join(t, "bin")}:/usr/bin:/bin`, MISE_CONFIG_DIR: join(t, "cfg"),
      MISE_GLOBAL_CONFIG_FILE: join(t, "cfg", "config.toml"), MISE_TRUSTED_CONFIG_PATHS: t,
    },
    stdin: "ignore", stdout: "pipe", stderr: "pipe",
  });
  expect(p.exitCode, p.stderr.toString()).toBe(0);
  const [argv, profile] = readFileSync(join(t, "calls"), "utf8").split("\n");
  return { argv, profile };
}

describe.skipIf(!MISE)("bootstrap hand-over", () => {
  it("runs the phase task in the dots repo", () => {
    expect(bootstrap([]).argv).toBe(`run -C ${join(t, ".local/share/dots")} bootstrap:hook:pre-dotfiles`);
  });

  it("passes -E as DOTS_PROFILE", () => {
    expect(bootstrap(["-E", "container"]).profile).toBe("container");
    expect(bootstrap(["-E", "desktop,dev"]).profile).toBe("desktop,dev");
  });

  it("passes the environments saved in miserc.local.toml", () => {
    writeFileSync(join(t, "cfg", "miserc.local.toml"), 'env = ["desktop", "dev"]\n');
    expect(bootstrap([]).profile).toBe("desktop,dev");
  });

  it("defaults to desktop when no environment is selected", () => {
    expect(bootstrap([]).profile).toBe("desktop");
  });
});
