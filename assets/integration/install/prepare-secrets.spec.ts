#!/usr/bin/env bun
// prepare-secrets: the archive install --secrets opens. Uses --fixture only; never real keys.
import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import { mkdtempSync, rmSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

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
    const opened = sh(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "600000",
      "-in", archive, "-out", zip, "-pass", "pass:dots-fixture"]);
    expect(opened.code).toBe(0);
    const listing = sh(["unzip", "-l", zip]).out;
    for (const path of ["age/keys.txt", "ssh/id_ed25519", "ssh/id_ed25519.pub", "gnupg/README", "gh/hosts.yml"]) {
      expect(listing).toContain(path);
    }
    expect(listing).not.toContain("github_token");
  });

  it("cannot be opened with another passphrase", () => {
    const archive = join(dir, "fixture.zip.enc");
    sh(["/bin/bash", script, "--fixture", "--output", archive]);
    const opened = sh(["openssl", "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "600000",
      "-in", archive, "-out", join(dir, "x.zip"), "-pass", "pass:wrong"]);
    const listed = sh(["unzip", "-l", join(dir, "x.zip")]);
    expect(opened.code !== 0 || listed.code !== 0).toBe(true);
  });
});
