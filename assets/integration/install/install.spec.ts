#!/usr/bin/env bun
// install behaviour through --dry-run and the fixture archive: checks read the real machine, nothing changes.
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir, userInfo } from "node:os";
import { join, resolve } from "node:path";

const repo = resolve(import.meta.dir, "../../..");
const script = join(repo, "install");
const me = userInfo().username;
const isMac = process.platform === "darwin";

let fixtureDir: string;
let fixture: string;
beforeAll(() => {
  fixtureDir = mkdtempSync(join(tmpdir(), "install-fixture-"));
  fixture = join(fixtureDir, "fixture.zip.enc");
  const r = Bun.spawnSync(["/bin/bash", join(repo, "script/prepare-secrets"), "--fixture", "--output", fixture]);
  if (r.exitCode !== 0) throw new Error(`prepare-secrets failed: ${r.stderr}`);
});
afterAll(() => rmSync(fixtureDir, { recursive: true, force: true }));

let home: string;
beforeEach(() => {
  home = mkdtempSync(join(tmpdir(), "install-home-"));
});
afterEach(() => rmSync(home, { recursive: true, force: true }));

function run(args: string[], env: Record<string, string> = {}) {
  const r = Bun.spawnSync(["/bin/bash", script, ...args], {
    env: { PATH: process.env.PATH ?? "", HOME: home, DOTS_CONTAINER: "0", ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: r.exitCode, out: r.stdout.toString(), err: r.stderr.toString() };
}

describe("install", () => {
  describe("arguments", () => {
    it("prints usage with --help", () => {
      const r = run(["--help"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain("--secrets <archive>");
      expect(r.out).toContain("--dry-run");
    });

    it.each([
      [["--bogus"], "unknown option '--bogus'"],
      [["--user", "Bad Name"], "invalid user name 'Bad Name'"],
      [["--secrets", "/no/such/file.zip.enc"], "is not a file"],
    ])("rejects %p", (args, message) => {
      const r = run(args as string[]);
      expect(r.code).toBe(2);
      expect(r.err).toContain(message as string);
    });
  });

  describe("dry run as the current user", () => {
    it("keeps the existing user and plans mise, links and bootstrap", () => {
      const r = run(["--user", me, "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain(`user ${me} exists`);
      expect(r.out).toContain("MISE_VERSION=v");
      expect(r.out).toContain(`would: ln -snf ${repo} ${home}/.local/share/dots`);
      expect(r.out).toContain(`would: ln -snf ../.local/share/dots/config/mise ${home}/.config/mise`);
      expect(r.out).toContain(`would: ${home}/.local/bin/mise bootstrap`);
      expect(r.out).toContain("mise bootstrap -E desktop");
    });

    it("changes no link that is already right", () => {
      mkdirSync(join(home, ".local/share"), { recursive: true });
      mkdirSync(join(home, ".config"), { recursive: true });
      symlinkSync(repo, join(home, ".local/share/dots"));
      symlinkSync("../.local/share/dots/config/mise", join(home, ".config/mise"));
      const r = run(["--user", me, "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).not.toContain("would: ln");
      expect(r.out.match(/is linked/g)?.length).toBe(2);
    });
  });

  describe("secrets archive", () => {
    it("opens the archive and plans copying without overwriting", () => {
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(r.code).toBe(0);
      expect(r.out).toMatch(/would: cp -R \S+\/files\/ssh /);
      expect(r.out).toContain(`${home}/.config/ssh`);
      expect(r.out).toMatch(/would: install -m 0600 \S+\/files\/gh\/hosts\.yml /);
      expect(r.out).toContain("config/age/keys.txt"); // planned, or reported as existing on a set-up Mac
    });

    it("stops with exit code 2 on a wrong passphrase", () => {
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "wrong" });
      expect(r.code).toBe(2);
      expect(r.err).toContain("cannot open");
      expect(r.out).not.toContain("would: cp");
    });
  });

  describe("dry run for another user", () => {
    it("plans creating a missing user and stops before switching", () => {
      const r = run(["--user", "dots-test-nobody", "--dry-run"]);
      expect(r.code).toBe(0);
      expect(r.out).toContain(isMac ? "sysadminctl -addUser dots-test-nobody" : "useradd -m -g dots-test-nobody");
      expect(r.out).toContain("would: continue as dots-test-nobody");
    });
  });

  describe("containers", () => {
    it("uses the container profile, skips the login shell and plans passwordless sudo", () => {
      const r = run(["--user", me, "--dry-run"], { DOTS_CONTAINER: "1" });
      expect(r.code).toBe(0);
      expect(r.out).toContain("profile container");
      expect(r.out).toContain("visudo -cf");
      expect(r.out).toContain("mise bootstrap -E container --skip user --yes");
    });
  });
});
