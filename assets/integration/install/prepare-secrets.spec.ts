#!/usr/bin/env bun
// prepare-secrets: the archive install --secrets opens. Uses --fixture or a fake HOME; never real keys.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, rmSync, statSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";

const repo = resolve(import.meta.dir, "../../..");
const script = join(repo, "script/prepare-secrets");

let dir: string;
beforeEach(() => {
  dir = mkdtempSync(join(tmpdir(), "prepare-secrets-"));
});
afterEach(() => rmSync(dir, { recursive: true, force: true }));

function sh(cmd: string[], env: Record<string, string> = {}) {
  const r = Bun.spawnSync(cmd, { env: { PATH: process.env.PATH ?? "", HOME: dir, ...env }, stdout: "pipe", stderr: "pipe" });
  return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString() };
}

function open(archive: string, pass: string, out = join(dir, "opened.zip")) {
  return sh(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "600000", "-md", "sha256",
    "-in", archive, "-out", out, "-pass", `pass:${pass}`]);
}

function put(path: string, body = "x\n") {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, body);
}

describe("prepare-secrets", () => {
  it("rejects unknown options", () => {
    const r = sh(["/bin/bash", script, "--bogus"]);
    expect(r.code).toBe(2);
    expect(r.err).toContain("unknown option '--bogus'");
  });

  it("writes an encrypted, owner-only fixture archive with the install layout", () => {
    const archive = join(dir, "fixture.zip.enc");
    const made = sh(["/bin/bash", script, "--fixture", "--output", archive]);
    expect(made.code).toBe(0);
    expect(made.out.trim()).toBe(archive);
    expect(statSync(archive).mode & 0o777).toBe(0o600);

    const zip = join(dir, "fixture.zip");
    expect(open(archive, "dots-fixture", zip).code).toBe(0);
    const listing = sh(["unzip", "-l", zip]).out;
    for (const path of ["age/keys.txt", "ssh/id_ed25519", "ssh/id_ed25519.pub", "gnupg/README", "gh/hosts.yml"]) {
      expect(listing).toContain(path);
    }
    expect(listing).not.toContain("github_token");
  });

  it("cannot be opened with another passphrase", () => {
    const archive = join(dir, "fixture.zip.enc");
    sh(["/bin/bash", script, "--fixture", "--output", archive]);
    const opened = open(archive, "wrong", join(dir, "x.zip"));
    const listed = sh(["unzip", "-l", join(dir, "x.zip")]);
    expect(opened.code !== 0 || listed.code !== 0).toBe(true);
  });

  it("forces mode 600 when the output already exists with mode 644", () => {
    const archive = join(dir, "fixture.zip.enc");
    writeFileSync(archive, "old");
    chmodSync(archive, 0o644);
    expect(sh(["/bin/bash", script, "--fixture", "--output", archive]).code).toBe(0);
    expect(statSync(archive).mode & 0o777).toBe(0o600);
  });

  it("leaves no output file when a stage fails", () => {
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "zip"), "#!/bin/sh\nexit 1\n");
    chmodSync(join(bin, "zip"), 0o755);
    const archive = join(dir, "fixture.zip.enc");
    const r = sh(["/bin/bash", script, "--fixture", "--output", archive], { PATH: `${bin}:${process.env.PATH}` });
    expect(r.code).not.toBe(0);
    expect(existsSync(archive)).toBe(false);
  });

  it("fixture ignores an ambient DOTS_SECRETS_PASSPHRASE", () => {
    const archive = join(dir, "fixture.zip.enc");
    const made = sh(["/bin/bash", script, "--fixture", "--output", archive], { DOTS_SECRETS_PASSPHRASE: "other" });
    expect(made.code).toBe(0);
    expect(open(archive, "dots-fixture").code).toBe(0);
  });

  it("packs a fake home, skipping runtime files and the missing token", () => {
    const home = join(dir, "home");
    const cfg = join(home, ".config");
    put(join(home, ".local/share/dots/config/age/keys.txt"));
    put(join(cfg, "ssh/keys/id_test.key"));
    symlinkSync("keys/id_test.key", join(cfg, "ssh/id_test"));
    for (const f of ["ssh/S.agent", "gnupg/.#lk0x1", "gnupg/random_seed", "gnupg/pubring.kbx~", "gnupg/pubring.kbx", "gh/hosts.yml"]) {
      put(join(cfg, f));
    }
    const bin = join(dir, "bin");
    mkdirSync(bin);
    writeFileSync(join(bin, "gh"), "#!/bin/sh\nexit 1\n");
    chmodSync(join(bin, "gh"), 0o755);
    const archive = join(dir, "real.zip.enc");
    const r = sh(["/bin/bash", script, "--output", archive],
      { HOME: home, XDG_CONFIG_HOME: cfg, DOTS_SECRETS_PASSPHRASE: "t", PATH: `${bin}:${process.env.PATH}` });
    expect(r.err).toBe("");
    expect(r.code).toBe(0);
    expect(open(archive, "t").code).toBe(0);
    const listing = sh(["unzip", "-l", join(dir, "opened.zip")]).out;
    for (const path of ["age/keys.txt", "ssh/id_test", "ssh/keys/id_test.key", "gnupg/pubring.kbx", "gh/hosts.yml"]) {
      expect(listing).toContain(path);
    }
    for (const path of ["S.agent", ".#lk0x1", "random_seed", "pubring.kbx~", "github_token"]) {
      expect(listing).not.toContain(path);
    }
  });

  it("rejects a link pointing outside the archive", () => {
    const home = join(dir, "home");
    const cfg = join(home, ".config");
    mkdirSync(join(cfg, "ssh"), { recursive: true });
    symlinkSync("/etc/hosts", join(cfg, "ssh/id_bad"));
    const archive = join(dir, "bad.zip.enc");
    const r = sh(["/bin/bash", script, "--output", archive],
      { HOME: home, XDG_CONFIG_HOME: cfg, DOTS_SECRETS_PASSPHRASE: "t" });
    expect(r.code).toBe(1);
    expect(r.err).toContain("is a link to");
    expect(existsSync(archive)).toBe(false);
  });
});
