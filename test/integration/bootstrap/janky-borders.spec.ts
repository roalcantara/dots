#!/usr/bin/env bun
// The borders-build step: JankyBorders built from qeesung's fork at a pinned commit (upstream leaves outlines behind
// in Mission Control on macOS 27).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep, skipIf } from "./step";

const REPO = join(import.meta.dir, "../../..");
const STEP = "borders/build.sh";
const REV = "f56533701a3ce0fae1801f2c11586a62098fe727";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "janky-borders-"));
  mkdirSync(join(t, "bin"));
  const stub = (name: string, body: string) => {
    writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(t, "bin", name), 0o755);
  };
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  stub("brew", "exit 0");
  stub("git", `echo "git $*" >> "${t}/calls"; [ "$1" = clone ] && mkdir -p "$4/.git"; exit 0`);
  stub("make", `echo "make $*" >> "${t}/calls"; [ "\${STUB_MAKE_EXIT:-0}" = 0 ] || exit 1; mkdir -p "$2/bin" && touch "$2/bin/borders"`);
  stub("launchctl", `echo "launchctl $*" >> "${t}/calls"`);
  stub("id", "echo 501");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const r = runStep(STEP, {
    PATH: `${join(t, "bin")}:/usr/bin:/bin`,
    HOME: t,
    DOTS_PROFILE: "desktop",
    DOTS_UNAME: env.STUB_OS ?? "Darwin",
    ...env,
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8").trim().split("\n") : [];
  return { code: r.code, out: r.out, err: r.err, calls };
}
const jb = () => join(t, ".local/share/janky-borders");

describe("borders/build.sh up-to-date check", () => {
  it("skip_if is true when the built revision matches the pin, false otherwise", () => {
    const env = { HOME: t };
    expect(skipIf(STEP, env)).toBe(false);
    mkdirSync(join(jb(), "bin"), { recursive: true });
    writeFileSync(join(jb(), "bin/.rev"), `${REV}\n`);
    expect(skipIf(STEP, env)).toBe(true);
    writeFileSync(join(jb(), "bin/.rev"), "another-revision\n");
    expect(skipIf(STEP, env)).toBe(false);
  });
});

describe("bootstrap janky-borders step", () => {
  it("runs in the final phase after the tiling checks", () => {
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap", STEP), "utf8")).toContain(REV);
    const phases = Bun.TOML.parse(readFileSync(join(REPO, ".mise/tasks/bootstrap/phases.toml"), "utf8")) as {
      "bootstrap:hook:final": { run: { task: string }[] };
    };
    const order = phases["bootstrap:hook:final"].run.map((s) => s.task);
    expect(order.indexOf("bootstrap:borders:build")).toBeGreaterThan(order.indexOf("bootstrap:tiling:checks"));
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
    expect(r.code).toBe(0);
  });

  it("does nothing off macOS", () => {
    expect(snippet({ STUB_OS: "Linux" }).calls).toEqual([]);
  });
});
