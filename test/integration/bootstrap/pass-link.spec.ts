#!/usr/bin/env bun
// The pass-link step in the bootstrap task (config/mise/conf.d/bootstrap.toml): links ~/.local/bin/pass to
// Homebrew's gopass (else any gopass on PATH), and never replaces a real pass.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readlinkSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
type BootstrapConfig = { tasks: { bootstrap: { run: string } } };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as BootstrapConfig;
const task = parsed.tasks.bootstrap.run;
const SNIPPET = task.match(/# pass-link: begin\n[\s\S]*?# pass-link: end\n/)?.[0] ?? "";

let t: string;
const exe = (path: string) => {
  writeFileSync(path, "#!/bin/sh\nexit 0\n");
  chmodSync(path, 0o755);
};
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "pass-link-"));
  mkdirSync(join(t, "brew", "bin"), { recursive: true });
  mkdirSync(join(t, "other"));
  exe(join(t, "brew", "bin", "gopass"));
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

const link = () => join(t, ".local", "bin", "pass");
function snippet(env: Record<string, string>) {
  const p = Bun.spawnSync(["bash", "-c", `warn() { echo "warn $1" >&2; }\n${SNIPPET}echo done`], {
    env: { PATH: "/usr/bin:/bin", HOME: t, ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

// Only meaningful where neither pass nor gopass is a system package.
const clean = !["/usr/bin/pass", "/bin/pass", "/usr/bin/gopass", "/bin/gopass"].some(existsSync);

describe.skipIf(!clean)("bootstrap pass-link", () => {
  it("is in the bootstrap task, after the gopass store clone", () => {
    expect(SNIPPET).toContain('"$HOME/.local/bin/pass"');
    expect(task.indexOf("# pass-link: begin")).toBeGreaterThan(task.indexOf("pass-store.git"));
  });

  it("links pass to gopass in $HOMEBREW_PREFIX", () => {
    const r = snippet({ HOMEBREW_PREFIX: join(t, "brew") });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
    expect(readlinkSync(link())).toBe(join(t, "brew", "bin", "gopass"));
  });

  it("falls back to gopass on PATH without a Homebrew prefix", () => {
    exe(join(t, "other", "gopass"));
    snippet({ PATH: `${join(t, "other")}:/usr/bin:/bin` });
    expect(readlinkSync(link())).toBe(join(t, "other", "gopass"));
  });

  it("refreshes its own link", () => {
    mkdirSync(join(t, ".local", "bin"), { recursive: true });
    symlinkSync(join(t, "gone", "gopass"), link());
    snippet({ HOMEBREW_PREFIX: join(t, "brew"), PATH: `${join(t, ".local", "bin")}:/usr/bin:/bin` });
    expect(readlinkSync(link())).toBe(join(t, "brew", "bin", "gopass"));
  });

  it("never replaces a real pass", () => {
    exe(join(t, "other", "pass"));
    snippet({ HOMEBREW_PREFIX: join(t, "brew"), PATH: `${join(t, "other")}:/usr/bin:/bin` });
    expect(existsSync(link())).toBe(false);
  });

  it("does nothing without gopass", () => {
    const r = snippet({});
    expect(r.out).toContain("done");
    expect(() => lstatSync(link())).toThrow();
  });
});
