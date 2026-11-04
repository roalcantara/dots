#!/usr/bin/env bun
// The gopass-keyring check in the bootstrap task (config/mise/conf.d/bootstrap.toml): warns when the gopass
// identity keyring still uses a passphrase, or when its unlock file is missing; never fails the bootstrap.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
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

  it("does nothing without an identities file", () => expect(snippet(null).err).toBe(""));

  // Only meaningful where gopass is not a system package (e.g. apt's /usr/bin/gopass).
  it.skipIf(existsSync("/usr/bin/gopass") || existsSync("/bin/gopass"))("does nothing without gopass", () => {
    rmSync(join(t, "bin", "gopass"));
    expect(snippet(SCRYPT).err).toBe("");
  });

  it("checks every file of a comma-separated age.keyring-identities", () => {
    mkdirSync(join(t, ".config", "age"), { recursive: true });
    writeFileSync(join(t, ".config", "age", "keys.txt"), "AGE-SECRET-KEY-1TEST\n");
    expect(snippet(X25519, { STUB_KID: "~/.config/age/keys.txt, ~/.config/age/keys.txt" }).err).toBe("");
    const r = snippet(X25519, { STUB_KID: "~/.config/age/keys.txt,~/gone.txt" });
    expect(r.err).toContain(`gopass keyring identity file missing: ${join(t, "gone.txt")}`);
    expect(r.err).not.toContain("keys.txt");
  });
});

const tools = ["gopass", "age-keygen", "expect", "git"].every((c) => Bun.which(c) !== null);

describe.skipIf(!tools)("gopass keyring switch (end to end)", () => {
  it("after reencrypt, gopass decrypts with no tty and no passphrase; without the key it fails", () => {
    const h = mkdtempSync(join(tmpdir(), "gopass-e2e-"));
    // Only the four tools, never pinentry: pinentry-mac could open a dialog or write a Keychain item named
    // like the real one (GnuPG / pass/age-identities). /usr/bin and /bin have no pinentry.
    mkdirSync(join(h, "bin"));
    for (const c of ["gopass", "age-keygen", "expect", "git"]) symlinkSync(realpathSync(Bun.which(c) as string), join(h, "bin", c)); // real binary, never a mise shim
    const env: Record<string, string> = {
      PATH: `${join(h, "bin")}:/usr/bin:/bin`, HOME: h, XDG_CONFIG_HOME: join(h, ".config"),
      XDG_DATA_HOME: join(h, ".local/share"), XDG_CACHE_HOME: join(h, ".cache"), XDG_RUNTIME_DIR: join(h, "run"),
      GOPASS_NO_NOTIFY: "true", GIT_CONFIG_GLOBAL: join(h, "gitconfig"), GIT_CONFIG_NOSYSTEM: "1", TERM: "dumb",
    };
    // A fresh env (not process.env), so GOPASS_CONFIG / GOPASS_CONFIG_HOME / GOPASS_HOMEDIR never leak in.
    const sh = (cmd: string, extra: Record<string, string> = {}) =>
      Bun.spawnSync(["bash", "-c", cmd], {
        env: { ...env, ...extra }, stdin: "ignore", stdout: "pipe", stderr: "pipe", timeout: 30_000,
      });
    try {
      mkdirSync(env.XDG_RUNTIME_DIR as string, { recursive: true, mode: 0o700 });
      writeFileSync(env.GIT_CONFIG_GLOBAL as string, "[user]\n  email = t@example.com\n  name = T\n[commit]\n  gpgsign = false\n");
      const pass = { GOPASS_AGE_PASSWORD: "lab-pass-123" };

      expect(sh("gopass setup --crypto age --storage fs --name T --email t@example.com", pass).exitCode).toBe(0);
      expect(sh("echo the-secret-value | gopass insert -f tokens/demo", pass).exitCode).toBe(0);
      expect(sh("head -n 2 ~/.config/gopass/age/identities").stdout.toString()).toContain("-> scrypt");

      expect(sh("mkdir -p ~/.config/age && (umask 077; age-keygen -o ~/.config/age/keys.txt)").exitCode).toBe(0);
      expect(sh("gopass config age.keyring-identities '~/.config/age/keys.txt'").exitCode).toBe(0);
      expect(sh('gopass config age.keyring-recipients "$(age-keygen -y ~/.config/age/keys.txt)"').exitCode).toBe(0);
      const exp = [
        "set timeout 30",
        "spawn gopass age identities reencrypt",
        "expect {",
        "  -re {\\[y/N/q\\]} { send \"y\\r\"; exp_continue }",
        "  eof {}",
        "  timeout { exit 9 }",
        "}",
        "catch wait r",
        "exit [lindex $r 3]",
      ].join("\n");
      writeFileSync(join(h, "re.exp"), exp);
      expect(sh(`expect ${join(h, "re.exp")}`, pass).exitCode).toBe(0);
      expect(sh("head -n 2 ~/.config/gopass/age/identities").stdout.toString()).toContain("-> X25519");

      expect(sh("gopass config age.agent-enabled false").exitCode).toBe(0); // no agent cache can serve the show
      const after = sh("gopass show -o tokens/demo");
      expect(after.exitCode).toBe(0);
      expect(after.stdout.toString().trim()).toBe("the-secret-value");

      sh("mv ~/.config/age/keys.txt ~/keys.moved");
      const missing = sh("gopass show -o tokens/demo");
      expect(missing.exitCode).not.toBe(0);
      expect(missing.stdout.toString() + missing.stderr.toString()).toContain("failed to decrypt");
    } finally {
      sh("gopass age agent stop >/dev/null 2>&1; true");
      rmSync(h, { recursive: true, force: true });
    }
  }, 120_000);
});
