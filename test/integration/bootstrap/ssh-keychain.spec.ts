#!/usr/bin/env bun
// The ssh-keychain step in the bootstrap task (config/mise/conf.d/bootstrap.toml): on macOS, puts the GitHub key
// (git's signing key) in the agent, storing its passphrase in Keychain once; never fails the bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
type BootstrapConfig = { tasks: { bootstrap: { run: string } } };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as BootstrapConfig;
const task = parsed.tasks.bootstrap.run;
const SNIPPET = task.match(/# ssh-keychain: begin\n[\s\S]*?# ssh-keychain: end\n/)?.[0] ?? "";
const KEY = "256 SHA256:testfingerprint github (ED25519)";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "ssh-keychain-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, ".ssh"));
  const stub = (name: string, body: string) => {
    writeFileSync(join(t, "bin", name), `#!/bin/sh\n${body}\n`);
    chmodSync(join(t, "bin", name), 0o755);
  };
  // The agent's identities live in $T/agent; Keychain holds the key when STUB_KEYCHAIN is set.
  stub("ssh-add", `echo "$*" >> "${t}/calls"
case "$1" in
  -l) [ -s "${t}/agent" ] && { cat "${t}/agent"; exit 0; }; echo "The agent has no identities."; exit 1 ;;
  --apple-load-keychain) [ -n "$STUB_KEYCHAIN" ] && echo "${KEY}" > "${t}/agent"; exit 0 ;;
  --apple-use-keychain) echo "${KEY}" > "${t}/agent"; exit 0 ;;
esac`);
  stub("ssh-keygen", `echo "${KEY}"`);
  stub("uname", 'echo "${STUB_OS:-Darwin}"');
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}, keyFiles = true) {
  if (keyFiles) {
    writeFileSync(join(t, ".ssh", "id_ed25519_github"), "private\n");
    writeFileSync(join(t, ".ssh", "id_ed25519_github.pub"), "ssh-ed25519 AAAA github\n");
  }
  const warn = 'warn() { printf "bootstrap: %s failed, continuing\\n" "$1" >&2; }\n';
  // os.setsid() detaches from the terminal, so /dev/tty is unavailable (the no-terminal case); setsid(1) is not on macOS.
  const p = Bun.spawnSync(["python3", "-c", "import os,sys;os.setsid();os.execvp(sys.argv[1],sys.argv[1:])",
    "bash", "-c", `${warn}${SNIPPET}echo done`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, DOTS_SSH_BIN: join(t, "bin"), ...env },
    stdout: "pipe", stderr: "pipe",
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8") : "";
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString(), calls };
}

describe("bootstrap ssh-keychain step", () => {
  it("is in the bootstrap task, desktop only", () => {
    expect(SNIPPET).toContain("--apple-use-keychain");
    expect(task.indexOf("# ssh-keychain: begin")).toBeGreaterThan(task.indexOf("$desktop || exit 0"));
  });

  it("does nothing off macOS", () => {
    const r = snippet({ STUB_OS: "Linux" });
    expect(r.code).toBe(0);
    expect(r.calls).toBe("");
    expect(r.err).toBe("");
  });

  it("does nothing when the key is not on this machine", () => {
    const r = snippet({}, false);
    expect(r.out).toContain("done");
    expect(r.calls).toBe("");
  });

  it("is silent when the agent already has the key", () => {
    writeFileSync(join(t, "agent"), `${KEY}\n`);
    const r = snippet();
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
    expect(r.calls).not.toContain("--apple-load-keychain");
  });

  it("loads the key from Keychain without asking", () => {
    const r = snippet({ STUB_KEYCHAIN: "1" });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
    expect(r.calls).toContain("--apple-load-keychain");
    expect(r.calls).not.toContain("--apple-use-keychain");
  });

  it("without Keychain or a terminal, says what to run and continues", () => {
    const r = snippet();
    expect(r.code).toBe(0);
    expect(r.out).toContain("done");
    expect(r.err).toContain(`ssh-add --apple-use-keychain ${t}/.ssh/id_ed25519_github`);
    expect(r.calls).not.toContain("--apple-use-keychain");
  });
});
