#!/usr/bin/env bun
// install behaviour through --dry-run and the fixture archive: checks read the real machine, nothing changes.
import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it } from "bun:test";
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  readlinkSync,
  realpathSync,
  rmSync,
  statSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
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

const dotsTemps = () => readdirSync("/tmp").filter((n) => n.startsWith("dots-"));
const newTemps = (before: string[]) => dotsTemps().filter((n) => !before.includes(n));

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
      [["--tz", "x'; y", "--dry-run"], "invalid timezone"],
      [["--tz", "../x", "--dry-run"], "invalid timezone"],
      [["--branch", "../../a/b/c", "--dry-run"], "invalid branch"],
      [["--branch", "-x", "--dry-run"], "invalid branch"],
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
      expect(r.out).toMatch(/ v\d{4}\.\d+\.\d+\n/);
      expect(r.out).toContain(`would: ln -snf ${repo} ${home}/.local/share/dots`);
      expect(r.out).toContain(`would: ln -snf ../.local/share/dots/config/mise ${home}/.config/mise`);
      expect(r.out).toContain(`would: ${home}/.local/bin/mise bootstrap`);
      expect(r.out).toContain("mise bootstrap -E desktop");
      // On a host, forcing dotfiles would replace a real ~/.ssh folder with a link and delete its keys.
      expect(r.out).not.toContain("--force-dotfiles");
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

    it("plans replacing an empty secrets folder but removes nothing in a dry run", () => {
      mkdirSync(join(home, ".config/ssh"), { recursive: true });
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(r.code).toBe(0);
      expect(r.out).toContain(`would: rmdir ${home}/.config/ssh`);
      expect(r.out).toMatch(/would: cp -R \S+\/files\/ssh /);
      expect(existsSync(join(home, ".config/ssh"))).toBe(true);
    });

    it("keeps a secrets folder that already has files", () => {
      mkdirSync(join(home, ".config/ssh"), { recursive: true });
      writeFileSync(join(home, ".config/ssh/known_hosts"), "kept");
      const r = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(r.code).toBe(0);
      expect(r.out).toContain(`${home}/.config/ssh exists`);
      expect(r.out).not.toMatch(/would: (rmdir|cp -R \S+\/files\/ssh)/);
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

  describe("temporary files", () => {
    it("leaves none after a dry run or a wrong passphrase", () => {
      const before = dotsTemps();
      const ok = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "dots-fixture" });
      expect(ok.code).toBe(0);
      const bad = run(["--user", me, "--secrets", fixture, "--dry-run"], { DOTS_SECRETS_PASSPHRASE: "wrong" });
      expect(bad.code).toBe(2);
      expect(newTemps(before)).toEqual([]);
    });
  });

  describe("the user stage", () => {
    const mk = (template: string, dir = false) =>
      Bun.spawnSync(["mktemp", ...(dir ? ["-d"] : []), template]).stdout.toString().trim();

    it("rejects a DOTS_SECRETS path that is not a plain dots-secrets folder, and deletes nothing", () => {
      const victim = mkdtempSync(join(tmpdir(), "install-victim-"));
      writeFileSync(join(victim, "keep"), "x");
      const r = run(["--user", me], {
        DOTS_STAGE: "user",
        DOTS_SECRETS: `/tmp/dots-secrets.abcdef/..${victim}`,
      });
      expect(r.code).toBe(2);
      expect(r.err).toContain("untrusted");
      expect(readFileSync(join(victim, "keep"), "utf8")).toBe("x");
      rmSync(victim, { recursive: true, force: true });
    });

    it("does not delete a trusted folder under --dry-run", () => {
      const dir = mk("/tmp/dots-secrets.XXXXXX", true);
      const r = run(["--user", me, "--dry-run"], { DOTS_STAGE: "user", DOTS_SECRETS: dir });
      const kept = statSync(dir).isDirectory();
      rmSync(dir, { recursive: true, force: true });
      expect(r.code).toBe(0);
      expect(kept).toBe(true);
    });
  });

  describe("a real run in a fake checkout and home", () => {
    let base: string;
    let checkout: string;
    let stubs: string;
    beforeEach(() => {
      base = mkdtempSync(join(tmpdir(), "install-real-"));
      checkout = realpathSync(base) + "/checkout";
      stubs = join(base, "stubs");
      mkdirSync(join(checkout, "script"), { recursive: true });
      mkdirSync(join(checkout, "config/mise"), { recursive: true });
      mkdirSync(join(checkout, "config/age"), { recursive: true });
      copyFileSync(script, join(checkout, "install"));
      mkdirSync(join(home, ".local/bin"), { recursive: true });
      const mise = join(home, ".local/bin/mise");
      writeFileSync(
        mise,
        '#!/bin/sh\nif [ "$1" = --version ]; then echo "2026.10.21 stub"; else echo "$*" >> "$HOME/mise.log"; fi\n',
      );
      chmodSync(mise, 0o755);
      mkdirSync(stubs);
      writeFileSync(join(stubs, "flatpak"), "#!/bin/sh\nexit 0\n");
      chmodSync(join(stubs, "flatpak"), 0o755);
      mkdirSync(join(home, ".config/gh"), { recursive: true });
      writeFileSync(join(home, ".config/gh/hosts.yml"), "mine\n");
    });
    afterEach(() => rmSync(base, { recursive: true, force: true }));

    const real = () =>
      Bun.spawnSync(["/bin/bash", join(checkout, "install"), "--user", me, "--secrets", fixture], {
        env: {
          PATH: `${stubs}:${process.env.PATH ?? ""}`,
          HOME: home,
          DOTS_CONTAINER: "0",
          DOTS_SECRETS_PASSPHRASE: "dots-fixture",
        },
        stdout: "pipe",
        stderr: "pipe",
      });
    const mode = (p: string) => statSync(p).mode & 0o777;

    it("places links and secrets, bootstraps, and changes nothing on a second run", () => {
      const before = dotsTemps();
      const r = real();
      expect(r.stderr.toString()).toBe("");
      expect(r.exitCode).toBe(0);
      expect(readlinkSync(join(home, ".local/share/dots"))).toBe(checkout);
      expect(readlinkSync(join(home, ".config/mise"))).toBe("../.local/share/dots/config/mise");
      expect(mode(join(home, ".config/ssh"))).toBe(0o700);
      for (const f of readdirSync(join(home, ".config/ssh"))) {
        if (statSync(join(home, ".config/ssh", f)).isFile()) expect(mode(join(home, ".config/ssh", f))).toBe(0o600);
      }
      expect(mode(join(checkout, "config/age/keys.txt"))).toBe(0o600);
      expect(readFileSync(join(home, "mise.log"), "utf8")).toContain("bootstrap -E desktop");
      expect(readFileSync(join(home, ".config/gh/hosts.yml"), "utf8")).toBe("mine\n");
      expect(newTemps(before)).toEqual([]);

      const mtimes = () =>
        [join(checkout, "config/age/keys.txt"), ...readdirSync(join(home, ".config/ssh")).map((f) => join(home, ".config/ssh", f))].map(
          (p) => statSync(p).mtimeMs,
        );
      const m1 = mtimes();
      const r2 = real();
      expect(r2.exitCode).toBe(0);
      expect(mtimes()).toEqual(m1);
      expect(readFileSync(join(home, "mise.log"), "utf8").match(/bootstrap/g)?.length).toBe(2);
      expect(newTemps(before)).toEqual([]);
    });

    it("runs the script the root stage writes, as the user stage, and removes what it was handed", () => {
      const mk = (template: string, dir = false) =>
        Bun.spawnSync(["mktemp", ...(dir ? ["-d"] : []), template]).stdout.toString().trim();
      const emitted = mk("/tmp/dots-install.XXXXXX");
      const env = {
        PATH: `${stubs}:${process.env.PATH ?? ""}`,
        HOME: home,
        DOTS_CONTAINER: "0",
      };
      // DOTS_INSTALL_EMIT_SCRIPT makes a dry run write the script switch_to_user would hand over, and stop.
      const gen = Bun.spawnSync(["/bin/bash", join(checkout, "install"), "--user", me, "--dry-run"], {
        env: { ...env, DOTS_INSTALL_EMIT_SCRIPT: emitted },
      });
      expect(gen.exitCode).toBe(0);
      chmodSync(emitted, 0o755);
      const secrets = mk("/tmp/dots-secrets.XXXXXX", true);
      mkdirSync(join(secrets, "ssh"));
      writeFileSync(join(secrets, "ssh/id"), "key\n");
      writeFileSync(join(secrets, "github_token"), "tok");
      const r = Bun.spawnSync(["/bin/bash", emitted, "--user", me], {
        env: { ...env, DOTS_STAGE: "user", DOTS_SECRETS: secrets, DOTS_CHECKOUT: checkout },
        stdout: "pipe",
        stderr: "pipe",
      });
      const left = [existsSync(secrets), existsSync(emitted)];
      rmSync(secrets, { recursive: true, force: true });
      rmSync(emitted, { force: true });
      expect(r.stderr.toString()).toBe("");
      expect(r.exitCode).toBe(0);
      expect(left).toEqual([false, false]);
      expect(mode(join(home, ".config/ssh"))).toBe(0o700);
      expect(mode(join(home, ".config/ssh/id"))).toBe(0o600);
      expect(readFileSync(join(home, "mise.log"), "utf8")).toContain("bootstrap -E desktop");
    });
  });

  describe("containers", () => {
    it("uses the container profile, skips the login shell and plans passwordless sudo", () => {
      const r = run(["--user", me, "--dry-run"], { DOTS_CONTAINER: "1" });
      expect(r.code).toBe(0);
      expect(r.out).toContain("profile container");
      expect(r.out).toContain("visudo -cf");
      expect(r.out).toContain("mise bootstrap --force-dotfiles -E container --skip user --yes");
    });
  });
});
