#!/usr/bin/env bun
import { describe, expect, it } from "bun:test";
import { readFileSync } from "node:fs";
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
