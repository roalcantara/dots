#!/usr/bin/env bun
// The tiling-checks step: on a macOS desktop, clones the kb Raycast extension and warns about what bootstrap cannot
// do itself (docs/TILING.md).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { runStep } from "./step";

const REPO = join(import.meta.dir, "../../..");
const STEP = "tiling/checks.sh";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "tiling-checks-"));
  mkdirSync(join(t, "bin"));
  const stub = (name: string, body: string) => {
    writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(t, "bin", name), 0o755);
  };
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  stub("brew", "exit 0");
  stub("git", `echo "git $*" >> "${t}/calls"; [ "$1" = clone ] && mkdir -p "$3"; exit "\${STUB_GIT_EXIT:-0}"`);
  stub("csrutil", 'echo "System Integrity Protection status: ${STUB_SIP:-unknown (Custom Configuration).}"');
  stub("yabai", 'exit "${STUB_YABAI_EXIT:-0}"');
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const r = runStep(STEP, {
    PATH: `${join(t, "bin")}:/usr/bin:/bin`,
    HOME: t,
    usage_profile: "desktop",
    DOTS_UNAME: env.STUB_OS ?? "Darwin",
    DOTS_CSRUTIL: join(t, "bin/csrutil"),
    DOTS_YABAI: join(t, "bin/yabai"),
    ...env,
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8") : "";
  return { code: r.code, out: r.out, err: r.err, calls };
}

describe("bootstrap tiling-checks step", () => {
  it("runs in the tiling part, on desktops only", () => {
    const step = readFileSync(join(REPO, ".mise/tasks/bootstrap", STEP), "utf8");
    expect(step).toContain("docs/TILING.md");
    expect(step).toContain("has_profile desktop || exit 0");
    const parts = Bun.TOML.parse(readFileSync(join(REPO, ".mise/tasks/bootstrap/parts.toml"), "utf8")) as {
      "dots:setup:tiling": { run: { task: string }[] };
    };
    const order = parts["dots:setup:tiling"].run.map((s) => s.task);
    expect(order).toContain("bootstrap:tiling:checks");
  });

  it("does nothing off macOS", () => {
    const r = snippet({ STUB_OS: "Linux" });
    expect(r.code).toBe(0);
    expect(r.out + r.err).toBe("");
    expect(r.calls).toBe("");
  });

  it("clones kb-raycast to ~/Work/kb when it is missing, and leaves an existing checkout alone", () => {
    expect(snippet().calls).toBe(`git clone git@github.com:roalcantara/kb-raycast.git ${join(t, "Work/kb")}\n`);
    rmSync(join(t, "calls"));
    expect(snippet().calls).toBe("");
  });

  it("warns, and carries on, when the clone fails", () => {
    const r = snippet({ STUB_GIT_EXIT: "1" });
    expect(r.code).toBe(0);
    expect(r.err).toContain("clone kb-raycast");
  });

  it("says nothing when everything is in place", () => {
    mkdirSync(join(t, "Work/kb"), { recursive: true });
    const r = snippet();
    expect(r.err).toBe("");
  });

  it("explains how to partly disable SIP when it is fully on", () => {
    mkdirSync(join(t, "Work/kb"), { recursive: true });
    const r = snippet({ STUB_SIP: "enabled." });
    expect(r.err).toContain("csrutil enable --without fs --without debug --without nvram");
    expect(r.err).toContain("docs/TILING.md");
  });

  it("points at Accessibility when yabai does not answer", () => {
    mkdirSync(join(t, "Work/kb"), { recursive: true });
    const r = snippet({ STUB_YABAI_EXIT: "1" });
    expect(r.code).toBe(0);
    expect(r.err).toContain("Accessibility");
  });
});
