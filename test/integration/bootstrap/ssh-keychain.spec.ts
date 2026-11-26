#!/usr/bin/env bun
// The ssh-keychain step: on macOS, puts the GitHub key (git's signing key) in the agent, storing its passphrase in
// Keychain once; never fails the bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { STEPS } from "./step";

const REPO = join(import.meta.dir, "../../..");
const STEP = "ssh/keychain.sh";
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
  // bootstrap_init's brew shellenv would otherwise put the Mac's real /opt/homebrew/bin first.
  stub("brew", "exit 0");
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(env: Record<string, string> = {}, keyFiles = true) {
  if (keyFiles) {
    writeFileSync(join(t, ".ssh", "id_ed25519_github"), "private\n");
    writeFileSync(join(t, ".ssh", "id_ed25519_github.pub"), "ssh-ed25519 AAAA github\n");
  }
  // os.setsid() detaches from the terminal, so /dev/tty is unavailable (the no-terminal case); setsid(1) is not on macOS.
  const p = Bun.spawnSync(["python3", "-c", "import os,sys;os.setsid();os.execvp(sys.argv[1],sys.argv[1:])",
    "bash", join(STEPS, STEP)], {
    env: {
      PATH: `${join(t, "bin")}:/usr/bin:/bin`,
      HOME: t,
      DOTS_PROFILE: "desktop",
      DOTS_UNAME: env.STUB_OS ?? "Darwin",
      DOTS_SSH_BIN: join(t, "bin"),
      ...env,
    },
    stdin: "ignore", stdout: "pipe", stderr: "pipe",
  });
  const calls = existsSync(join(t, "calls")) ? readFileSync(join(t, "calls"), "utf8") : "";
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString(), calls };
}

describe("bootstrap ssh-keychain step", () => {
  it("is in the final phase, desktop only", () => {
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap", STEP), "utf8")).toContain("--apple-use-keychain");
    expect(readFileSync(join(REPO, ".mise/tasks/bootstrap", STEP), "utf8")).toContain("has_profile desktop || exit 0");
  });

  it("does nothing off macOS", () => {
    const r = snippet({ STUB_OS: "Linux" });
    expect(r.code).toBe(0);
    expect(r.calls).toBe("");
    expect(r.err).toBe("");
  });

  it("does nothing when the key is not on this machine", () => {
    expect(snippet({}, false).calls).toBe("");
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
    expect(r.err).toContain(`ssh-add --apple-use-keychain ${t}/.ssh/id_ed25519_github`);
    expect(r.calls).not.toContain("--apple-use-keychain");
  });
});
