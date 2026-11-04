#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  appsNotFromCasks,
  backupArgs,
  classifyRepo,
  excludeLines,
  expand,
  forgetArgs,
  parseManifest,
  passwordEnv,
  renderManifest,
  repoPath,
  restoreArgs,
  type Facts,
} from "../../../script/backup";

const REPO = join(import.meta.dir, "../../..");
const ctx = { home: "/Users/me", host: "mac", root: "/Volumes/b" };
const text = `
[repository]
path = "machines/{host}/restic"
password_command = "gopass show -o backups/restic"
[backup]
paths = ["~", "/opt/x"]
tags = ["{host}"]
exclude_caches = true
[retention]
daily = 7
weekly = 0
monthly = 12
[[exclude]]
pattern = "~/.cache"
why = "cache"
[[exclude]]
pattern = "**/node_modules"
why = "deps"
`;
const m = parseManifest(text);

describe("parseManifest", () => {
  it("fills defaults", () => {
    expect(m.repository.root).toBe("/Volumes/backups");
    expect(parseManifest('[repository]\npath="r"\n[backup]\npaths=["~"]\n').backup.tags).toEqual([]);
  });
  it("rejects a missing path, empty paths and an exclude without why", () => {
    expect(() => parseManifest('[backup]\npaths=["~"]\n')).toThrow("repository.path");
    expect(() => parseManifest('[repository]\npath="r"\n[backup]\npaths=[]\n')).toThrow("backup.paths");
    expect(() =>
      parseManifest('[repository]\npath="r"\n[backup]\npaths=["~"]\n[[exclude]]\npattern="x"\n'),
    ).toThrow("exclude[0].why");
  });
  it("accepts the repository manifest, and every exclude has a reason", () => {
    const real = parseManifest(readFileSync(join(REPO, "config/restic/backup.toml"), "utf8"));
    expect(real.exclude.length).toBeGreaterThan(10);
    for (const e of real.exclude) expect(e.why.length).toBeGreaterThan(0);
    expect(real.exclude.map((e) => e.pattern)).not.toContain("~/Work/dots");
  });
});

describe("expand", () => {
  it("expands a leading ~ and {host} only", () => {
    expect(expand("~", ctx)).toBe("/Users/me");
    expect(expand("~/.cache", ctx)).toBe("/Users/me/.cache");
    expect(expand("a~/b", ctx)).toBe("a~/b");
    expect(expand("machines/{host}/restic", ctx)).toBe("machines/mac/restic");
  });
});

describe("repoPath and excludeLines", () => {
  it("joins the root and the expanded path", () => {
    expect(repoPath(m, ctx)).toBe("/Volumes/b/machines/mac/restic");
  });
  it("writes one expanded pattern per line", () => {
    expect(excludeLines(m, ctx)).toBe("/Users/me/.cache\n**/node_modules\n");
  });
});

describe("passwordEnv", () => {
  it("uses password_command when no restic password variable is set", () => {
    expect(passwordEnv(m, {})).toEqual({ RESTIC_PASSWORD_COMMAND: "gopass show -o backups/restic" });
  });
  it("leaves any restic password variable alone, even an empty one", () => {
    expect(passwordEnv(m, { RESTIC_PASSWORD: "x" })).toEqual({});
    expect(passwordEnv(m, { RESTIC_PASSWORD_COMMAND: "" })).toEqual({});
  });
});

describe("restic arguments", () => {
  it("backup", () => {
    expect(backupArgs(m, ctx, "/tmp/ex")).toEqual([
      "backup", "/Users/me", "/opt/x", "--exclude-file", "/tmp/ex", "--exclude-caches", "--tag", "mac",
    ]);
  });
  it("forget omits zero keeps and prunes", () => {
    expect(forgetArgs(m)).toEqual(["forget", "--keep-daily", "7", "--keep-monthly", "12", "--prune"]);
  });
  it("forget refuses an all-zero retention", () => {
    expect(() => forgetArgs(parseManifest('[repository]\npath="r"\n[backup]\npaths=["~"]\n'))).toThrow("retention");
  });
  it("restore maps the old home and anchors includes", () => {
    expect(
      restoreArgs({ snapshot: "latest", fromHome: "/Users/old", target: "/Users/me", includes: ["Work", "~/Documents", "/Pictures"], dryRun: true }),
    ).toEqual([
      "restore", "latest:/Users/old", "--target", "/Users/me",
      "--include", "/Work", "--include", "/Documents", "--include", "/Pictures", "--dry-run", "--verbose",
    ]);
  });
});

describe("classifyRepo", () => {
  it("lists every risk", () => {
    expect(classifyRepo({ name: "x", dirty: 2, unpushed: 1, stashes: 3, remotes: 0 })).toEqual([
      "no remote", "2 uncommitted", "1 unpushed", "3 stashed",
    ]);
    expect(classifyRepo({ name: "x", dirty: 0, unpushed: 0, stashes: 0, remotes: 1 })).toEqual([]);
  });
});

describe("appsNotFromCasks", () => {
  it("keeps apps no installed cask provides", () => {
    const json = JSON.stringify({
      casks: [
        { token: "ghostty", artifacts: [{ app: ["Ghostty.app"] }, { binary: ["x"] }] },
        { token: "zed", artifacts: [{ app: [{ target: "Zed.app" }] }] },
      ],
    });
    expect(appsNotFromCasks(["Ghostty.app", "Zed.app", "Keynote.app"], json)).toEqual(["Keynote.app"]);
  });
});

describe("renderManifest", () => {
  const facts: Facts = {
    date: "2026-11-04", host: "mac", user: "me", macos: "27.2", filevault: "FileVault is Off.",
    timeMachine: "No destinations configured.",
    repos: [{ name: "carrie", dirty: 90, unpushed: 1, stashes: 0, remotes: 0 }, { name: "ok", dirty: 0, unpushed: 0, stashes: 0, remotes: 1 }],
    nonGit: [{ name: "rust", size: "56G" }], brewCheck: "missing: x", untrustedTaps: ["can1357/tap"],
    appsNotCasks: ["Keynote.app"], largest: [{ path: "Work", size: "68G" }], notes: ["mas not installed"],
  };
  const md = renderManifest(facts);
  it("puts risks first and names the host and user for the restore", () => {
    expect(md.indexOf("## Risks")).toBeLessThan(md.indexOf("## Repositories"));
    expect(md).toContain("carrie: no remote, 90 uncommitted, 1 unpushed");
    expect(md).not.toContain("ok: ");
    expect(md).toContain("DOTS_BACKUP_HOST=mac");
    expect(md).toContain("--from-home /Users/me");
    expect(md).toContain("brew trust can1357/tap");
    expect(md).toContain("FileVault is Off.");
  });
});

const SCRIPT = join(REPO, "script/backup.ts");
const FIX = join(import.meta.dir, "fixtures");
const hasTaplo = Bun.which("taplo") !== null;
const hasRestic = Bun.which("restic") !== null;

function cli(args: string[], env: Record<string, string>) {
  const p = Bun.spawnSync(["bun", SCRIPT, ...args], {
    env: {
      PATH: process.env.PATH ?? "",
      XDG_STATE_HOME: process.env.XDG_STATE_HOME ?? join(process.env.HOME ?? "", ".local/state"),
      ...env,
    },
    stdout: "pipe",
    stderr: "pipe",
  });
  return { code: p.exitCode, out: p.stdout.toString(), err: p.stderr.toString() };
}

describe.skipIf(!hasTaplo)("schema (taplo check)", () => {
  const check = (f: string) => Bun.spawnSync(["taplo", "check", f], { stdout: "pipe", stderr: "pipe" }).exitCode;
  it("accepts the repository manifest", () => expect(check(join(REPO, "config/restic/backup.toml"))).toBe(0));
  it("rejects an exclude without why", () => expect(check(join(FIX, "no-why.toml"))).not.toBe(0));
  it("rejects an unknown key", () => expect(check(join(FIX, "unknown-key.toml"))).not.toBe(0));
});

describe("errors", () => {
  it("exits 1 naming the root when it is missing", () => {
    const r = cli(["snapshots"], { HOME: tmpdir(), DOTS_BACKUP_ROOT: "/nonexistent/root", DOTS_BACKUP_HOST: "t" });
    expect(r.code).toBe(1);
    expect(r.err).toContain("backup root not found: /nonexistent/root");
    expect(r.err).toContain("DOTS_BACKUP_ROOT");
  });
  it("exits 2 when restore has no --include", () => {
    const r = cli(["restore"], { HOME: tmpdir(), DOTS_BACKUP_ROOT: tmpdir(), DOTS_BACKUP_HOST: "t" });
    expect(r.code).toBe(2);
    expect(r.err).toContain("--include");
  });
  it("exits 2 on an unknown command", () => {
    expect(cli(["nope"], { HOME: tmpdir() }).code).toBe(2);
  });
});

describe.skipIf(!hasRestic)("end to end with restic", () => {
  it("init, backup, snapshots, restore one folder, skip excludes", () => {
    const t = mkdtempSync(join(tmpdir(), "backup-e2e-"));
    try {
      const home = join(t, "Users", "old"), root = join(t, "drive"), next = join(t, "Users", "new");
      mkdirSync(join(home, "docs"), { recursive: true });
      mkdirSync(join(home, "proj", "node_modules"), { recursive: true });
      mkdirSync(root);
      mkdirSync(next, { recursive: true });
      writeFileSync(join(home, "docs", "a.txt"), "a");
      writeFileSync(join(home, "proj", "main.ts"), "m");
      writeFileSync(join(home, "proj", "node_modules", "x.js"), "x");
      const manifest = join(t, "backup.toml");
      writeFileSync(manifest, `[repository]\npath = "machines/{host}/restic"\n[backup]\npaths = ["~"]\ntags = ["{host}"]\n[retention]\ndaily = 1\n[[exclude]]\npattern = "**/node_modules"\nwhy = "deps"\n`);
      const env = { HOME: home, DOTS_BACKUP_ROOT: root, DOTS_BACKUP_HOST: "e2e", DOTS_BACKUP_MANIFEST: manifest, RESTIC_PASSWORD: "test" };

      expect(cli(["init"], env).code).toBe(0);
      expect(existsSync(join(root, "machines/e2e/restic/config"))).toBe(true);
      expect(existsSync(join(root, "README.md"))).toBe(true);
      expect(cli(["init"], env).code).toBe(0); // second run: already a repository
      expect(cli(["backup"], env).code).toBe(0);
      expect(cli(["snapshots"], env).code).toBe(0);

      const r = cli(["restore", "--include", "proj"], { ...env, HOME: next });
      expect(r.code).toBe(0);
      expect(existsSync(join(next, "proj", "main.ts"))).toBe(true);
      expect(existsSync(join(next, "proj", "node_modules"))).toBe(false);
      expect(existsSync(join(next, "docs"))).toBe(false);
      expect(cli(["forget"], env).code).toBe(0);
    } finally {
      rmSync(t, { recursive: true, force: true });
    }
  }, 60_000);
});
