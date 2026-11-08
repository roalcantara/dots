#!/usr/bin/env bun
// The janky-borders step in the bootstrap task (config/mise/conf.d/bootstrap.toml): JankyBorders built from
// qeesung's fork at a pinned commit (upstream leaves outlines behind in Mission Control on macOS 27).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as { tasks: { bootstrap: { run: string } } }).tasks.bootstrap.run;
const SNIPPET = task.match(/# janky-borders: begin\n[\s\S]*?# janky-borders: end\n/)?.[0] ?? "";
const REV = "f56533701a3ce0fae1801f2c11586a62098fe727";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "janky-borders-"));
  mkdirSync(join(t, "bin"));
  const stub = (name: string, body: string) => {
    writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(t, "bin", name), 0o755);
  };
  stub("uname", 'echo "${STUB_OS:-Darwin}"');
  stub("git", `echo "git $*" >> "${t}/calls"; [ "$1" = clone ] && mkdir -p "$4/.git"; exit 0`);
  stub("make", `echo "make $*" >> "${t}/calls"; [ "\${STUB_MAKE_EXIT:-0}" = 0 ] || exit 1; mkdir -p "$2/bin" && touch "$2/bin/borders"`);
  stub("launchctl", `echo "launchctl $*" >> "${t}/calls"`);
  stub("id", "echo 501");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const warn = 'warn() { printf "bootstrap: %s failed, continuing\\n" "$1" >&2; }\n';
  const p = Bun.spawnSync(["bash", "-c", `${warn}${SNIPPET}echo done`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8").trim().split("\n") : [];
  return { out: p.stdout.toString(), err: p.stderr.toString(), calls };
}
const jb = () => join(t, ".local/share/janky-borders");

describe("bootstrap janky-borders step", () => {
  it("runs in the bootstrap task after the tiling checks", () => {
    expect(SNIPPET).toContain(REV);
    expect(task.indexOf("# janky-borders: begin")).toBeGreaterThan(task.indexOf("# tiling-checks: end"));
  });

  it("clones the fork, builds the pinned commit and restarts the borders service", () => {
    const r = snippet();
    expect(r.calls).toEqual([
      `git clone -q https://github.com/qeesung/JankyBorders.git ${jb()}`,
      `git -C ${jb()} fetch -q origin`,
      `git -C ${jb()} checkout -q ${REV}`,
      `make -C ${jb()} -s`,
      "launchctl kickstart -k gui/501/dev.mise.borders",
    ]);
    expect(readFileSync(join(jb(), "bin/.rev"), "utf8").trim()).toBe(REV);
  });

  it("does nothing when the pinned commit is already built", () => {
    snippet();
    rmSync(join(t, "calls"));
    expect(snippet().calls).toEqual([]);
  });

  it("warns, keeps the old build and leaves the service alone when the build fails", () => {
    const r = snippet({ STUB_MAKE_EXIT: "1" });
    expect(r.err).toContain("build JankyBorders");
    expect(r.calls.some((c) => c.startsWith("launchctl"))).toBe(false);
    expect(existsSync(join(jb(), "bin/.rev"))).toBe(false);
    expect(r.out).toBe("done\n");
  });

  it("does nothing off macOS", () => {
    expect(snippet({ STUB_OS: "Linux" }).calls).toEqual([]);
  });
});
