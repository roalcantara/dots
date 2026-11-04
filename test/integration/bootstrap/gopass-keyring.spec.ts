#!/usr/bin/env bun
// The gopass-keyring check in the bootstrap task (config/mise/conf.d/bootstrap.toml): warns when the gopass
// identity keyring still uses a passphrase, or when its unlock file is missing; never fails the bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const REPO = join(import.meta.dir, "../../..");
type BootstrapConfig = { tasks: { bootstrap: { run: string } } };
const parsed = Bun.TOML.parse(readFileSync(join(REPO, "config/mise/conf.d/bootstrap.toml"), "utf8")) as BootstrapConfig;
const task = parsed.tasks.bootstrap.run;
const SNIPPET = task.match(/# gopass-keyring: begin\n[\s\S]*?# gopass-keyring: end\n/)?.[0] ?? "";

const SCRYPT = "age-encryption.org/v1\n-> scrypt eJReM2BS 18\nabc\n";
const X25519 = "age-encryption.org/v1\n-> X25519 biNcMGIhZRmsV0kIarefRzAg\nabc\n";

let t: string;
beforeEach(() => {
  t = mkdtempSync(join(tmpdir(), "gopass-keyring-"));
  mkdirSync(join(t, "bin"));
  mkdirSync(join(t, ".config", "gopass", "age"), { recursive: true });
  // Stub gopass: `gopass config age.keyring-identities` prints $STUB_KID.
  writeFileSync(join(t, "bin", "gopass"), '#!/bin/sh\n[ "$1 $2" = "config age.keyring-identities" ] && printf "%s\\n" "$STUB_KID"\nexit 0\n');
  chmodSync(join(t, "bin", "gopass"), 0o755);
});
afterEach(() => rmSync(t, { recursive: true, force: true }));

function snippet(identities: string | null, env: Record<string, string> = {}) {
  if (identities !== null) writeFileSync(join(t, ".config", "gopass", "age", "identities"), identities);
  const p = Bun.spawnSync(["bash", "-c", `${SNIPPET}echo done`], {
    env: { PATH: `${join(t, "bin")}:/usr/bin:/bin`, HOME: t, ...env },
    stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe("bootstrap gopass-keyring check", () => {
  it("is in the bootstrap task, after the store clone", () => {
    expect(SNIPPET).toContain("age.keyring-identities");
    expect(task.indexOf("# gopass-keyring: begin")).toBeGreaterThan(task.indexOf("pass-store.git"));
  });

  it("warns when the keyring still uses a passphrase, and continues", () => {
    const r = snippet(SCRYPT);
    expect(r.code).toBe(0);
    expect(r.out).toContain("done");
    expect(r.err).toContain("gopass keyring still uses a passphrase");
    expect(r.err).toContain("docs/REINSTALL.md#one-secret-the-age-key");
  });

  it("is silent when the keyring is locked to an existing key file (~ expanded)", () => {
    mkdirSync(join(t, ".config", "age"), { recursive: true });
    writeFileSync(join(t, ".config", "age", "keys.txt"), "AGE-SECRET-KEY-1TEST\n");
    const r = snippet(X25519, { STUB_KID: "~/.config/age/keys.txt" });
    expect(r.code).toBe(0);
    expect(r.err).toBe("");
  });

  it("warns when the unlock file is missing", () => {
    const r = snippet(X25519, { STUB_KID: "~/.config/age/keys.txt" });
    expect(r.code).toBe(0);
    expect(r.err).toContain(`gopass keyring identity file missing: ${join(t, ".config/age/keys.txt")}`);
  });

  it("does nothing without gopass or without an identities file", () => {
    expect(snippet(null).err).toBe("");
    rmSync(join(t, "bin", "gopass"));
    expect(snippet(SCRYPT).err).toBe("");
  });
});
