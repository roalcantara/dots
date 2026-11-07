#!/usr/bin/env bun
// The tiling-checks step in the bootstrap task (config/mise/conf.d/bootstrap.toml): on a macOS desktop,
// clones the kb Raycast extension and warns about what bootstrap cannot do itself (docs/TILING.md).
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
const task = (Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as { tasks: { bootstrap: { run: string } } }).tasks.bootstrap.run;
const SNIPPET = task.match(/# tiling-checks: begin\n[\s\S]*?# tiling-checks: end\n/)?.[0] ?? "";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "tiling-checks-"));
  mkdirSync(join(t, "bin"));
  const stub = (name: string, body: string) => {
    writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(t, "bin", name), 0o755);
  };
  stub("uname", 'echo "${STUB_OS:-Darwin}"');
  stub("git", `echo "git $*" >> "${t}/calls"; [ "$1" = clone ] && mkdir -p "$3"; exit "\${STUB_GIT_EXIT:-0}"`);
  stub("csrutil", 'echo "System Integrity Protection status: ${STUB_SIP:-unknown (Custom Configuration).}"');
  stub("yabai", 'exit "${STUB_YABAI_EXIT:-0}"');
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}) {
  const warn = 'warn() { printf "bootstrap: %s failed, continuing\\n" "$1" >&2; }\n';
  const p = Bun.spawnSync(["bash", "-c", `${warn}${SNIPPET}echo done`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, DOTS_CSRUTIL: join(t, "bin/csrutil"), DOTS_YABAI: join(t, "bin/yabai"), ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8") : "";
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString(), calls };
}

describe("bootstrap tiling-checks step", () => {
  it("runs in the bootstrap task after the SSH key step, on desktops only", () => {
    expect(SNIPPET).not.toBe("");
    expect(task.indexOf("# tiling-checks: begin")).toBeGreaterThan(task.indexOf("# ssh-keychain: end"));
    expect(task.indexOf("# tiling-checks: begin")).toBeGreaterThan(task.indexOf("$desktop || exit 0"));
  });

  it("does nothing off macOS", () => {
    const r = snippet({ STUB_OS: "Linux" });
    expect(r.out).toBe("done\n");
    expect(r.err).toBe("");
    expect(r.calls).toBe("");
  });

  it("clones kb-raycast to ~/Work/kb when it is missing, and leaves an existing checkout alone", () => {
    expect(snippet().calls).toBe(`git clone git@github.com:roalcantara/kb-raycast.git ${join(t, "Work/kb")}\n`);
    rmSync(join(t, "calls"));
    expect(snippet().calls).toBe("");
  });

  it("warns, and carries on, when the clone fails", () => {
    const r = snippet({ STUB_GIT_EXIT: "1" });
    expect(r.out).toBe("done\n");
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
    expect(r.err).toContain("Accessibility");
    expect(r.out).toBe("done\n");
  });
});
