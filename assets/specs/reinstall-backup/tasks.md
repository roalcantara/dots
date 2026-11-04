<!-- markdownlint-disable -->
# Reinstall and backup — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** One manifest-driven restic backup (`config/restic/backup.toml` + JSON Schema), a read-only reinstall
audit, six mise tasks, and `assets/guides/REINSTALL_GUIDE.md` documenting every definition, reason and usage.

**Architecture:** `script/backup.ts` (Bun) holds exported pure functions (manifest parsing, path expansion,
restic argument building, audit rendering) plus a `main` that runs restic, git and brew. Thin global mise tasks in
`config/mise/conf.d/backup.toml` call it. `taplo check` enforces the schema in hk and at run time.

**Tech stack:** Bun 1.3.14 (`Bun.TOML`, `bun:test`), restic ≥ 0.17, taplo 0.10, hk, mise.

Read first: [requirements.md](requirements.md), [design.md](design.md), `assets/guides/GLOSSARY.md`,
`script/agent-skills.ts` (the pattern this copies).

## Ground rules

- Worktree: `~/Work/dots-backup`, branch `feat/reinstall-backup`. Never touch `~/Work/dots` (the owner's
  checkout, with 13 stashes).
- The repo has a SOPS git filter. Wrap git: `g() { git -c filter.sops.clean=cat -c filter.sops.smudge=cat "$@"; }`.
- Commit with `HK=0` only where a step says so; otherwise let hk run. Never `git add -A`: add the named files.
- Do not push. Do not create a gopass entry or any password. Do not run `backup`/`backup:init` against
  `/Volumes/backups` (the owner does that, Task 9); tests use temp folders.
- Commit messages: Conventional Commits, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## File map

| File | Action | Responsibility |
| --- | --- | --- |
| `config/restic/backup.toml` | Create | The backup policy (repository, paths, tags, retention, excludes with reasons) |
| `config/restic/backup.schema.json` | Create | JSON Schema for the manifest |
| `script/backup.ts` | Create | Pure functions + CLI: `audit`, `init`, `backup`, `snapshots`, `restore`, `forget` |
| `assets/integration/backup/backup.spec.ts` | Create | Unit, schema and end-to-end specs |
| `assets/integration/backup/fixtures/*.toml` | Create | Bad manifests for the schema specs |
| `config/mise/conf.d/backup.toml` | Create | Global mise tasks |
| `config/mise/config.toml` | Modify | Remove the scratch `[tasks.backup]` |
| `config/homebrew/Brewfile` | Modify | `brew "restic"` |
| `hk.pkl` | Modify | `taplo-schema` step |
| `assets/mise.toml` | Modify | `test all` also runs `integration backup` |
| `assets/guides/REINSTALL_GUIDE.md` | Create | The guide |
| `assets/guides/GLOSSARY.md`, `assets/guides/README.md`, `README.md` | Modify | Terms, index, pointers |

---

### Task 1: Install restic and confirm the facts the plan relies on

- [ ] **Step 1:** `brew install restic && restic version`. Expected: `restic 0.17.x` or newer. If older, STOP
  and report (the `snapshot:subfolder` syntax and `restore --dry-run` need 0.17).
- [ ] **Step 2:** Confirm `--include` semantics with a subfolder snapshot (this decides `restoreArgs`):

```bash
t=$(mktemp -d); export RESTIC_PASSWORD=x
mkdir -p "$t/home/docs" "$t/home/other" && echo a > "$t/home/docs/a.txt" && echo b > "$t/home/other/b.txt"
restic init --repo "$t/repo" -q
restic backup --repo "$t/repo" -q "$t/home"
restic restore --repo "$t/repo" "latest:$t/home" --target "$t/out" --include /docs
find "$t/out" -type f; rm -rf "$t"; unset RESTIC_PASSWORD
```

  Expected: only `$t/out/docs/a.txt`. If the file lands elsewhere or nothing restores, STOP and report the
  output (then `restoreArgs` must change before Task 3).

---

### Task 2: Manifest and schema

**Files:** create `config/restic/backup.schema.json`, `config/restic/backup.toml`,
`assets/integration/backup/fixtures/no-why.toml`, `assets/integration/backup/fixtures/unknown-key.toml`.

- [ ] **Step 1: The schema.** `config/restic/backup.schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://github.com/roalcantara/dots/config/restic/backup.schema.json",
  "title": "Dots backup manifest",
  "description": "Backup policy read by script/backup.ts. See assets/guides/REINSTALL_GUIDE.md.",
  "type": "object",
  "additionalProperties": false,
  "required": ["repository", "backup"],
  "properties": {
    "repository": {
      "type": "object",
      "additionalProperties": false,
      "required": ["path"],
      "properties": {
        "root": { "type": "string", "minLength": 1, "description": "Backup root; DOTS_BACKUP_ROOT overrides" },
        "path": { "type": "string", "minLength": 1, "description": "Repository path relative to root; {host} expands" },
        "password_command": { "type": "string", "minLength": 1, "description": "Becomes RESTIC_PASSWORD_COMMAND" }
      }
    },
    "backup": {
      "type": "object",
      "additionalProperties": false,
      "required": ["paths"],
      "properties": {
        "paths": { "type": "array", "minItems": 1, "items": { "type": "string", "minLength": 1 } },
        "tags": { "type": "array", "items": { "type": "string", "minLength": 1 } },
        "exclude_caches": { "type": "boolean" }
      }
    },
    "retention": {
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "daily": { "type": "integer", "minimum": 0 },
        "weekly": { "type": "integer", "minimum": 0 },
        "monthly": { "type": "integer", "minimum": 0 }
      }
    },
    "exclude": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["pattern", "why"],
        "properties": {
          "pattern": { "type": "string", "minLength": 1 },
          "why": { "type": "string", "minLength": 1 }
        }
      }
    }
  }
}
```

- [ ] **Step 2: The manifest.** `config/restic/backup.toml`:

```toml
#:schema ./backup.schema.json
# Backup policy for script/backup.ts (mise run backup, backup:restore, …).
# Every key, default and reason: assets/guides/REINSTALL_GUIDE.md, "The manifest".

[repository]
root = "/Volumes/backups"                          # DOTS_BACKUP_ROOT overrides
path = "machines/{host}/restic"                    # {host}: scutil --get LocalHostName, or DOTS_BACKUP_HOST
password_command = "gopass show -o backups/restic" # skipped when a RESTIC_PASSWORD* variable is set

[backup]
paths = ["~"]
tags = ["{host}"]
exclude_caches = true # also skip any folder holding a CACHEDIR.TAG

[retention]
daily = 7
weekly = 4
monthly = 12

[[exclude]]
pattern = "~/.cache"
why = "XDG cache; tools recreate it"

[[exclude]]
pattern = "~/Library/Caches"
why = "macOS app caches; apps recreate them"

[[exclude]]
pattern = "~/.Trash"
why = "Deleted files"

[[exclude]]
pattern = "~/Library/CloudStorage"
why = "Cloud drives (Google Drive, Dropbox); their provider syncs them, and reading them downloads every file"

[[exclude]]
pattern = "~/Library/Mobile Documents"
why = "iCloud Drive; iCloud syncs it"

[[exclude]]
pattern = "~/.omlx"
why = "oMLX models; the bootstrap task downloads them again"

[[exclude]]
pattern = "~/.local/share/mise"
why = "mise tool installs; mise bootstrap reinstalls them"

[[exclude]]
pattern = "~/.local/share/cargo"
why = "Cargo registry and builds; reinstalled from the Brewfile and mise"

[[exclude]]
pattern = "~/.local/share/rustup"
why = "Rust toolchains; rustup reinstalls them"

[[exclude]]
pattern = "~/.local/share/uv"
why = "uv tools and Pythons; the bootstrap task reinstalls them"

[[exclude]]
pattern = "~/.local/share/nvim"
why = "Neovim plugins; Lazy restores them from the lock file in dots"

[[exclude]]
pattern = "~/Library/Developer/Xcode/DerivedData"
why = "Xcode build output"

[[exclude]]
pattern = "~/Library/Developer/CoreSimulator"
why = "iOS simulators; Xcode downloads them again"

[[exclude]]
pattern = "~/Library/Containers/com.docker.docker"
why = "Docker Desktop VM disk; images are pulled or rebuilt"

[[exclude]]
pattern = "~/.orbstack"
why = "OrbStack VM disk; images are pulled or rebuilt"

[[exclude]]
pattern = "**/node_modules"
why = "JavaScript dependencies; the package manager reinstalls them"

[[exclude]]
pattern = "**/target"
why = "Rust and Maven build output"

[[exclude]]
pattern = "**/.gradle"
why = "Gradle caches"

[[exclude]]
pattern = "**/.venv"
why = "Python virtual environments; recreated from lock files"

[[exclude]]
pattern = "**/__pycache__"
why = "Python bytecode"

[[exclude]]
pattern = "**/.DS_Store"
why = "Finder metadata"
```

- [ ] **Step 3: Bad fixtures.** `assets/integration/backup/fixtures/no-why.toml`:

```toml
#:schema ../../../../config/restic/backup.schema.json
[repository]
path = "r"

[backup]
paths = ["~"]

[[exclude]]
pattern = "~/.cache"
```

  `assets/integration/backup/fixtures/unknown-key.toml`:

```toml
#:schema ../../../../config/restic/backup.schema.json
[repository]
path = "r"

[backup]
paths = ["~"]

[retenion]
daily = 7
```

- [ ] **Step 4: Check.**

```bash
cd ~/Work/dots-backup
taplo fmt config/restic/backup.toml assets/integration/backup/fixtures/*.toml
taplo check config/restic/backup.toml; echo "good=$?"
taplo check assets/integration/backup/fixtures/no-why.toml >/dev/null 2>&1; echo "no-why=$?"
taplo check assets/integration/backup/fixtures/unknown-key.toml >/dev/null 2>&1; echo "unknown=$?"
```

  Expected: `good=0`, `no-why=1`, `unknown=1`. If `taplo fmt` moved the inline comments, keep its output.

- [ ] **Step 5: Commit.**

```bash
g add config/restic/backup.toml config/restic/backup.schema.json assets/integration/backup/fixtures
g commit -m "feat(backup): Add the backup manifest and its schema

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3: Pure functions, test first

**Files:** create `assets/integration/backup/backup.spec.ts`, `script/backup.ts`.

- [ ] **Step 1: Write the failing unit specs.** `assets/integration/backup/backup.spec.ts`:

```ts
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
```

- [ ] **Step 2: Run it; it fails.** `cd assets && bun test integration/backup/` → fails: cannot find
  `../../../script/backup`.

- [ ] **Step 3: Write `script/backup.ts`** (pure part plus the CLI of Task 4 in one file; write it all now):

```ts
#!/usr/bin/env bun
// Manifest-driven restic backups and the reinstall audit.
// Design: assets/specs/reinstall-backup/design.md. Usage: assets/guides/REINSTALL_GUIDE.md.
import { existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { hostname, tmpdir } from "node:os";
import { join } from "node:path";

export type Exclude = { pattern: string; why: string };
export type Manifest = {
  repository: { root: string; path: string; password_command?: string };
  backup: { paths: string[]; tags: string[]; exclude_caches: boolean };
  retention: { daily: number; weekly: number; monthly: number };
  exclude: Exclude[];
};
export type Ctx = { home: string; host: string; root: string };
export type RepoState = { name: string; dirty: number; unpushed: number; stashes: number; remotes: number };
export type Facts = {
  date: string; host: string; user: string; macos: string; filevault: string; timeMachine: string;
  repos: RepoState[]; nonGit: { name: string; size: string }[]; brewCheck: string; untrustedTaps: string[];
  appsNotCasks: string[]; largest: { path: string; size: string }[]; notes: string[];
};
export type RestoreOpts = { snapshot: string; fromHome: string; target: string; includes: string[]; dryRun: boolean };

type Table = Record<string, unknown>;
const table = (v: unknown): Table => (v && typeof v === "object" && !Array.isArray(v) ? (v as Table) : {});
const strings = (v: unknown): string[] => (Array.isArray(v) ? v.filter((x): x is string => typeof x === "string") : []);
const int = (v: unknown): number => (typeof v === "number" && Number.isInteger(v) && v >= 0 ? v : 0);

export function parseManifest(text: string): Manifest {
  const raw = table(Bun.TOML.parse(text));
  const repo = table(raw.repository), backup = table(raw.backup), retention = table(raw.retention);
  const need = (ok: boolean, key: string) => {
    if (!ok) throw new Error(`manifest: missing or invalid ${key}`);
  };
  need(typeof repo.path === "string" && repo.path !== "", "repository.path");
  need(strings(backup.paths).length > 0, "backup.paths");
  const exclude = (Array.isArray(raw.exclude) ? raw.exclude : []).map((e, i) => {
    const t = table(e);
    need(typeof t.pattern === "string" && t.pattern !== "", `exclude[${i}].pattern`);
    need(typeof t.why === "string" && t.why !== "", `exclude[${i}].why`);
    return { pattern: t.pattern as string, why: t.why as string };
  });
  return {
    repository: {
      root: typeof repo.root === "string" ? repo.root : "/Volumes/backups",
      path: repo.path as string,
      password_command: typeof repo.password_command === "string" ? repo.password_command : undefined,
    },
    backup: { paths: strings(backup.paths), tags: strings(backup.tags), exclude_caches: backup.exclude_caches === true },
    retention: { daily: int(retention.daily), weekly: int(retention.weekly), monthly: int(retention.monthly) },
    exclude,
  };
}

export function expand(s: string, ctx: Pick<Ctx, "home" | "host">): string {
  const homed = s === "~" ? ctx.home : s.startsWith("~/") ? ctx.home + s.slice(1) : s;
  return homed.replaceAll("{host}", ctx.host);
}

export const repoPath = (m: Manifest, ctx: Ctx): string => join(ctx.root, expand(m.repository.path, ctx));

export const excludeLines = (m: Manifest, ctx: Ctx): string =>
  m.exclude.map((e) => `${expand(e.pattern, ctx)}\n`).join("");

const PASSWORD_VARS = ["RESTIC_PASSWORD", "RESTIC_PASSWORD_FILE", "RESTIC_PASSWORD_COMMAND"];

// `in`, not truthiness: RESTIC_PASSWORD_COMMAND= (empty) means "prompt me", used when gopass is not restored yet.
export function passwordEnv(m: Manifest, env: Record<string, string | undefined>): Record<string, string> {
  if (PASSWORD_VARS.some((v) => v in env)) return {};
  return m.repository.password_command ? { RESTIC_PASSWORD_COMMAND: m.repository.password_command } : {};
}

export const backupArgs = (m: Manifest, ctx: Ctx, excludeFile: string): string[] => [
  "backup",
  ...m.backup.paths.map((p) => expand(p, ctx)),
  "--exclude-file", excludeFile,
  ...(m.backup.exclude_caches ? ["--exclude-caches"] : []),
  ...m.backup.tags.flatMap((t) => ["--tag", expand(t, ctx)]),
];

export function forgetArgs(m: Manifest): string[] {
  const keep = (["daily", "weekly", "monthly"] as const)
    .filter((k) => m.retention[k] > 0)
    .flatMap((k) => [`--keep-${k}`, String(m.retention[k])]);
  if (keep.length === 0) throw new Error("retention: every keep is 0; refusing to forget");
  return ["forget", ...keep, "--prune"];
}

export const restoreArgs = (o: RestoreOpts): string[] => [
  "restore", `${o.snapshot}:${o.fromHome}`, "--target", o.target,
  ...o.includes.flatMap((p) => ["--include", `/${p.replace(/^~\//, "").replace(/^\/+/, "")}`]),
  ...(o.dryRun ? ["--dry-run", "--verbose"] : []),
];

export function classifyRepo(s: RepoState): string[] {
  const risks: string[] = [];
  if (s.remotes === 0) risks.push("no remote");
  if (s.dirty) risks.push(`${s.dirty} uncommitted`);
  if (s.unpushed) risks.push(`${s.unpushed} unpushed`);
  if (s.stashes) risks.push(`${s.stashes} stashed`);
  return risks;
}

export function appsNotFromCasks(apps: string[], caskJson: string): string[] {
  const provided = new Set<string>();
  for (const cask of strictArray(table(safeJson(caskJson)).casks)) {
    for (const artifact of strictArray(table(cask).artifacts)) {
      for (const app of strictArray(table(artifact).app)) {
        if (typeof app === "string") provided.add(app);
        else if (typeof table(app).target === "string") provided.add(table(app).target as string);
      }
    }
  }
  return apps.filter((a) => !provided.has(a));
}
function strictArray(v: unknown): unknown[] {
  return Array.isArray(v) ? v : [];
}
function safeJson(s: string): unknown {
  try {
    return JSON.parse(s);
  } catch {
    return {};
  }
}

const CHECKLIST = [
  "Age key and restic password are in the password manager (they are the only secrets dots cannot restore)",
  "2FA recovery codes and app licence keys are in the password manager",
  "Every repository above is pushed, or its risk is accepted (the restic snapshot holds it)",
  "Browser sync is on, or bookmarks and profiles are exported",
  "`mise run backup` finished, `restic check` passed, and a test restore worked",
];

export function renderManifest(f: Facts): string {
  const risky = f.repos.map((r) => [r.name, classifyRepo(r)] as const).filter(([, r]) => r.length);
  const lines = [
    `# Reinstall audit: ${f.host}, ${f.date}`, "",
    `macOS ${f.macos}, user \`${f.user}\`. Restore on the new machine with:`, "",
    "```sh", `DOTS_BACKUP_HOST=${f.host} mise run backup:restore -- --from-home /Users/${f.user} --include Work --dry-run`, "```", "",
    "## Risks", "",
    ...risky.map(([n, r]) => `- ${n}: ${r.join(", ")}`),
    ...f.nonGit.map((d) => `- ~/Work/${d.name}: not a git repository (${d.size}); only the snapshot holds it`),
    ...f.untrustedTaps.map((t) => `- untrusted tap ${t}: run \`brew trust ${t}\` after the reinstall`),
    ...(f.appsNotCasks.length ? [`- ${f.appsNotCasks.length} app(s) not in the Brewfile: see apps.txt`] : []),
    ...(f.filevault.includes("Off") ? ["- FileVault is off: turn it on in Setup Assistant"] : []),
    ...(risky.length || f.nonGit.length ? [] : ["- none in ~/Work"]),
    "", "## Repositories", "", "| Repo | Risks |", "| --- | --- |",
    ...f.repos.map((r) => `| ${r.name} | ${classifyRepo(r).join(", ") || "clean"} |`),
    "", "## System", "", `- FileVault: ${f.filevault}`, `- Time Machine: ${f.timeMachine}`,
    "", "## Packages", "", "```text", f.brewCheck.trim(), "```",
    "", "## Apps not provided by a cask", "", ...(f.appsNotCasks.length ? f.appsNotCasks.map((a) => `- ${a}`) : ["- none"]),
    "", "## Largest folders in ~", "", ...f.largest.map((l) => `- ${l.size}\t${l.path}`),
    ...(f.notes.length ? ["", "## Notes", "", ...f.notes.map((n) => `- ${n}`)] : []),
    "", "## Before you wipe", "", ...CHECKLIST.map((c) => `- [ ] ${c}`), "",
  ];
  return lines.join("\n");
}

// ---------- side effects ----------

type Run = { code: number; out: string };
function run(cmd: string[], opts: { cwd?: string; env?: Record<string, string>; timeoutMs?: number } = {}): Run {
  if (!Bun.which(cmd[0] as string)) return { code: 127, out: "" };
  const p = Bun.spawnSync(cmd, {
    cwd: opts.cwd, env: { ...process.env, ...opts.env }, timeout: opts.timeoutMs ?? 120_000, stdout: "pipe", stderr: "pipe",
  });
  return { code: p.exitCode ?? 1, out: `${p.stdout.toString()}${p.stderr.toString()}` };
}
const count = (s: string): number => s.split("\n").filter((l) => l.trim()).length;

function die(msg: string, code = 1): never {
  console.error(`backup: ${msg}`);
  process.exit(code);
}

function context(m: Manifest): Ctx {
  const home = process.env.HOME ?? die("HOME is not set");
  const scutil = process.platform === "darwin" ? run(["scutil", "--get", "LocalHostName"]) : { code: 1, out: "" };
  const host = process.env.DOTS_BACKUP_HOST || (scutil.code === 0 ? scutil.out.trim() : hostname().split(".")[0] ?? "host");
  return { home, host, root: process.env.DOTS_BACKUP_ROOT || m.repository.root };
}

function loadManifest(): Manifest {
  const file = process.env.DOTS_BACKUP_MANIFEST || join(import.meta.dir, "../config/restic/backup.toml");
  if (!existsSync(file)) die(`manifest not found: ${file}`);
  if (Bun.which("taplo")) {
    const check = run(["taplo", "check", file]);
    if (check.code !== 0) die(`manifest fails its schema (taplo check ${file}):\n${check.out}`);
  }
  try {
    return parseManifest(readFileSync(file, "utf8"));
  } catch (e) {
    return die((e as Error).message);
  }
}

function requireRoot(root: string): void {
  if (!existsSync(root) || !statSync(root).isDirectory()) die(`backup root not found: ${root} (mount the drive or set DOTS_BACKUP_ROOT)`);
}

function restic(args: string[], repo: string, env: Record<string, string>): number {
  if (!Bun.which("restic")) die("restic not found: brew install restic");
  const p = Bun.spawnSync(["restic", "--repo", repo, ...args], { env: { ...process.env, ...env }, stdio: ["inherit", "inherit", "inherit"] });
  return p.exitCode ?? 1;
}

function requireRepo(repo: string): void {
  if (!existsSync(join(repo, "config"))) die(`no repository at ${repo}: run mise run backup:init (or set DOTS_BACKUP_HOST to the old host)`);
}

const DRIVE_README = `# Backups

| Folder | Holds |
| --- | --- |
| machines/<host>/restic | restic repository (encrypted); password: gopass backups/restic, and the password manager |
| machines/<host>/exports/YYYY-MM-DD | reinstall audits (MANIFEST.md) and one-off copies (legacy/) |
| media | files that are not machine backups |
| archive | retired machines, moved whole from machines/ |

Restore (after the dots install): DOTS_BACKUP_HOST=<host> mise run backup:restore -- --include Work --dry-run
Without dots: restic --repo machines/<host>/restic restore latest:/Users/<user> --target ~ --include /Work
Guide: https://github.com/roalcantara/dots/blob/main/assets/guides/REINSTALL_GUIDE.md
`;

function init(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  if (existsSync(join(repo, "config"))) {
    console.log(`backup: ${repo} is already a repository`);
    return;
  }
  const env = passwordEnv(m, process.env);
  if (env.RESTIC_PASSWORD_COMMAND && run(["sh", "-c", env.RESTIC_PASSWORD_COMMAND]).code !== 0) {
    die(`password command failed: ${env.RESTIC_PASSWORD_COMMAND}\ncreate it: gopass generate backups/restic 32 (then copy it to your password manager)`);
  }
  mkdirSync(repo, { recursive: true });
  const code = restic(["init"], repo, env);
  if (code !== 0) process.exit(code);
  mkdirSync(join(ctx.root, "machines", ctx.host, "exports"), { recursive: true });
  const readme = join(ctx.root, "README.md");
  if (!existsSync(readme)) writeFileSync(readme, DRIVE_README);
}

function backup(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  const env = passwordEnv(m, process.env);
  const dir = mkdtempSync(join(tmpdir(), "dots-backup-"));
  const excludeFile = join(dir, "excludes.txt");
  writeFileSync(excludeFile, excludeLines(m, ctx));
  try {
    const code = restic(backupArgs(m, ctx, excludeFile), repo, env);
    if (code === 3) console.error("backup: some files could not be read (exit 3). Grant your terminal Full Disk Access, or exclude them.");
    else if (code !== 0) process.exit(code);
    const check = restic(["check"], repo, env);
    process.exit(check || code);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

export function parseRestoreFlags(args: string[]): { includes: string[]; snapshot: string; fromHome?: string; target?: string; dryRun: boolean } {
  const o = { includes: [] as string[], snapshot: "latest", fromHome: undefined as string | undefined, target: undefined as string | undefined, dryRun: false };
  for (let i = 0; i < args.length; i++) {
    const a = args[i], v = args[i + 1];
    if (a === "--dry-run") o.dryRun = true;
    else if (a === "--include" && v) (o.includes.push(v), i++);
    else if (a === "--snapshot" && v) ((o.snapshot = v), i++);
    else if (a === "--from-home" && v) ((o.fromHome = v), i++);
    else if (a === "--target" && v) ((o.target = v), i++);
    else throw new Error(`unknown or incomplete flag: ${a}`);
  }
  return o;
}

function snapshotHome(repo: string, snapshot: string, env: Record<string, string>): string | undefined {
  const p = Bun.spawnSync(["restic", "--repo", repo, "snapshots", "--json", snapshot], { env: { ...process.env, ...env }, stdout: "pipe", stderr: "inherit" });
  const list = strictArray(safeJson(p.stdout.toString()));
  // A snapshot of the manifest default (paths = ["~"]) has exactly one path: the old home.
  const paths = strings(table(list[list.length - 1]).paths);
  return paths.length === 1 ? paths[0] : undefined;
}

function restore(m: Manifest, ctx: Ctx, args: string[]): void {
  let flags: ReturnType<typeof parseRestoreFlags>;
  try {
    flags = parseRestoreFlags(args);
  } catch (e) {
    return die((e as Error).message, 2);
  }
  if (flags.includes.length === 0) die("restore needs at least one --include <path relative to the old home>, e.g. --include Work", 2);
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  const env = passwordEnv(m, process.env);
  const fromHome = flags.fromHome ?? snapshotHome(repo, flags.snapshot, env) ?? die("cannot tell the snapshot's home folder: pass --from-home /Users/<old user>", 2);
  process.exit(restic(restoreArgs({ snapshot: flags.snapshot, fromHome, target: flags.target ?? ctx.home, includes: flags.includes, dryRun: flags.dryRun }), repo, env));
}

function forget(m: Manifest, ctx: Ctx): void {
  requireRoot(ctx.root);
  const repo = repoPath(m, ctx);
  requireRepo(repo);
  let args: string[];
  try {
    args = forgetArgs(m);
  } catch (e) {
    return die((e as Error).message);
  }
  process.exit(restic(args, repo, passwordEnv(m, process.env)));
}

function collectFacts(ctx: Ctx, date: string): { facts: Facts; files: Record<string, string> } {
  const notes: string[] = [];
  const work = join(ctx.home, "Work");
  const repos: RepoState[] = [];
  const nonGit: { name: string; size: string }[] = [];
  const size = (p: string) => (run(["du", "-sh", p], { timeoutMs: 60_000 }).out.split("\t")[0] || "?").trim();
  if (existsSync(work)) {
    for (const name of readdirSync(work).sort()) {
      const dir = join(work, name);
      if (!statSync(dir).isDirectory()) continue;
      if (run(["git", "-C", dir, "rev-parse", "--git-dir"]).code !== 0) {
        nonGit.push({ name, size: size(dir) });
        continue;
      }
      const git = (...a: string[]) => run(["git", "-C", dir, ...a]).out;
      // A linked worktree has a .git file; it shares branches and stashes with its main checkout.
      const worktree = statSync(join(dir, ".git"), { throwIfNoEntry: false })?.isFile() === true;
      repos.push({
        name: worktree ? `${name} (worktree)` : name, dirty: count(git("status", "--porcelain")), unpushed: count(git("log", "--branches", "--not", "--remotes", "--oneline")),
        stashes: count(git("stash", "list")), remotes: count(git("remote")),
      });
    }
  } else notes.push(`${work} not found; repositories not audited`);

  const brewfile = join(import.meta.dir, "../config/homebrew/Brewfile");
  const brewEnv = { HOMEBREW_NO_AUTO_UPDATE: "1" };
  const has = (t: string) => {
    if (Bun.which(t)) return true;
    notes.push(`${t} not installed`);
    return false;
  };
  const files: Record<string, string> = {};
  let brewCheck = "brew not installed", caskJson = "{}";
  const untrustedTaps: string[] = [];
  if (has("brew")) {
    brewCheck = run(["brew", "bundle", "check", "--verbose", "--file", brewfile], { env: brewEnv }).out;
    const cleanup = run(["brew", "bundle", "cleanup", "--file", brewfile], { env: brewEnv }).out;
    for (const t of cleanup.matchAll(/untrusted tap (\S+?)\.?$/gm)) untrustedTaps.push(t[1] as string);
    files["brew-bundle-check.txt"] = brewCheck;
    files["brew-bundle-cleanup.txt"] = cleanup;
    files["brew-leaves.txt"] = run(["brew", "leaves"], { env: brewEnv }).out;
    files["brew-casks.txt"] = run(["brew", "list", "--cask"], { env: brewEnv }).out;
    caskJson = run(["brew", "info", "--cask", "--installed", "--json=v2"], { env: brewEnv }).out;
  }
  const apps = existsSync("/Applications") ? readdirSync("/Applications").filter((a) => a.endsWith(".app")).sort() : [];
  files["apps.txt"] = `${apps.join("\n")}\n`;
  if (has("mas")) files["mas.txt"] = run(["mas", "list"]).out;

  const largest = readdirSync(ctx.home)
    .filter((n) => n !== "Library" && statSync(join(ctx.home, n), { throwIfNoEntry: false })?.isDirectory())
    .map((n) => ({ path: n, kb: Number(run(["du", "-sk", join(ctx.home, n)], { timeoutMs: 60_000 }).out.split("\t")[0]) || 0 }))
    .sort((a, b) => b.kb - a.kb)
    .slice(0, 15)
    .map(({ path, kb }) => ({ path, size: kb >= 1048576 ? `${(kb / 1048576).toFixed(1)}G` : `${Math.round(kb / 1024)}M` }));

  const tsv = ["repo\tdirty\tunpushed\tstashes\tremotes", ...repos.map((r) => `${r.name}\t${r.dirty}\t${r.unpushed}\t${r.stashes}\t${r.remotes}`)];
  files["repos.tsv"] = `${tsv.join("\n")}\n`;
  const facts: Facts = {
    date, host: ctx.host, user: ctx.home.split("/").pop() ?? "", macos: run(["sw_vers", "-productVersion"]).out.trim() || process.platform,
    filevault: run(["fdesetup", "status"]).out.trim() || "unknown", timeMachine: run(["tmutil", "destinationinfo"]).out.trim().split("\n")[0] || "unknown",
    repos, nonGit, brewCheck, untrustedTaps, appsNotCasks: appsNotFromCasks(apps, caskJson), largest, notes,
  };
  return { facts, files };
}

function audit(m: Manifest, ctx: Ctx, args: string[]): void {
  const date = new Date().toISOString().slice(0, 10);
  const toStdout = args.includes("--stdout");
  if (!toStdout) requireRoot(ctx.root);
  const { facts, files } = collectFacts(ctx, date);
  const md = renderManifest(facts);
  if (toStdout) {
    console.log(md);
    return;
  }
  const dir = join(ctx.root, "machines", ctx.host, "exports", date);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, "MANIFEST.md"), md);
  for (const [name, body] of Object.entries(files)) writeFileSync(join(dir, name), body);
  const risks = md.split("## Repositories")[0]?.split("\n").filter((l) => l.startsWith("- ") && !l.includes("none in")).length ?? 0;
  console.log(`backup: audit written to ${dir} (${risks} risk(s); open MANIFEST.md)`);
}

const USAGE = "usage: bun script/backup.ts audit [--stdout] | init | backup | snapshots | restore --include P… [--snapshot ID] [--from-home DIR] [--target DIR] [--dry-run] | forget";

if (import.meta.main) {
  const [command, ...args] = process.argv.slice(2);
  if (!command || command === "-h" || command === "--help") die(USAGE, command ? 0 : 2);
  const m = loadManifest();
  const ctx = context(m);
  switch (command) {
    case "audit": audit(m, ctx, args); break;
    case "init": init(m, ctx); break;
    case "backup": backup(m, ctx); break;
    case "snapshots": requireRoot(ctx.root); requireRepo(repoPath(m, ctx)); process.exit(restic(["snapshots"], repoPath(m, ctx), passwordEnv(m, process.env)));
    case "restore": restore(m, ctx, args); break;
    case "forget": forget(m, ctx); break;
    default: die(USAGE, 2);
  }
}
```

- [ ] **Step 4: Run the unit specs.** `cd ~/Work/dots-backup/assets && bun test integration/backup/` → all pass.
  Then `bunx tsc --noEmit -p . ../script/backup.ts ../assets/integration/backup/backup.spec.ts` is **not**
  how this repo type-checks (its tsconfig only includes `specs/**`); instead run
  `bun build ../script/backup.ts --target bun --outdir "$TMPDIR/bk" >/dev/null && echo build-ok`.
  Expected: `build-ok`. Fix any error the build reports, keep the specs green.

- [ ] **Step 5: Commit.**

```bash
g add script/backup.ts assets/integration/backup/backup.spec.ts
g commit -m "feat(backup): Add the backup script and its unit specs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4: Schema, error and end-to-end specs

**Files:** modify `assets/integration/backup/backup.spec.ts` (append).

- [ ] **Step 1: Append.**

```ts
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";

const SCRIPT = join(REPO, "script/backup.ts");
const FIX = join(import.meta.dir, "fixtures");
const hasTaplo = Bun.which("taplo") !== null;
const hasRestic = Bun.which("restic") !== null;

function cli(args: string[], env: Record<string, string>) {
  const p = Bun.spawnSync(["bun", SCRIPT, ...args], { env: { PATH: process.env.PATH ?? "", ...env }, stdout: "pipe", stderr: "pipe" });
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
```

  Move the three new `import` lines to the top of the file, merging `readFileSync` into the `node:fs` import.

- [ ] **Step 2: Run.** `cd ~/Work/dots-backup/assets && bun test integration/backup/`. Expected: all pass, none
  skipped (restic and taplo are installed on this Mac). If the restore case fails, compare with Task 1 Step 2's
  output and fix `restoreArgs` (and its unit spec) to match restic's real behavior.

- [ ] **Step 3: Commit.**

```bash
g add assets/integration/backup/backup.spec.ts
g commit -m "test(backup): Cover the schema, errors and a restic round trip

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5: mise tasks, Brewfile, hk, test wiring

**Files:** create `config/mise/conf.d/backup.toml`; modify `config/mise/config.toml`, `config/homebrew/Brewfile`,
`hk.pkl`, `assets/mise.toml`.

- [ ] **Step 1: Tasks.** `config/mise/conf.d/backup.toml`:

```toml
# Backups and the reinstall audit: script/backup.ts, policy in config/restic/backup.toml.
# Guide: assets/guides/REINSTALL_GUIDE.md. Extra arguments go after `--`.

[tasks."reinstall:audit"]
description = "Read-only report of what a reinstall would lose, written to the backup drive (-- --stdout to print)"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" audit'

[tasks."backup:init"]
description = "Create this machine's restic repository on the backup drive"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" init'

[tasks.backup]
description = "Back up the home folder per config/restic/backup.toml, then restic check"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" backup'

[tasks."backup:snapshots"]
description = "List this machine's snapshots"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" snapshots'

[tasks."backup:restore"]
description = "Restore folders from a snapshot into the home folder (-- --include Work [--dry-run])"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" restore'

[tasks."backup:forget"]
description = "Apply the retention policy and prune"
tools = { bun = "1.3.14" }
run = 'bun "$HOME/.local/share/dots/script/backup.ts" forget'
```

- [ ] **Step 2: Remove the scratch task.** In `config/mise/config.toml`, delete `[tasks.backup]` and its whole
  `run = '''…'''` body (it starts at the line `[tasks.backup]`, about line 132, and ends at the closing `'''`).
  Then `grep -n 'meex900\|tasks.backup' config/mise/config.toml` → no output.

- [ ] **Step 3: Brewfile.** In `config/homebrew/Brewfile`, insert between `brew "python@3.14"…` and
  `brew "ruby"…`:

```ruby
brew "restic"  # Encrypted, deduplicated backups (config/restic/backup.toml)
```

- [ ] **Step 4: hk.** In `hk.pkl`, inside `stagingLinters`, after the `["taplo"] { … }` block:

```pkl
  ["taplo-schema"] {
    // Validates manifests that declare `#:schema` (taplo fmt does not); scoped so taplo
    // never fetches remote schemas for other TOML files.
    glob  = List("config/restic/*.toml")
    check = "taplo check {{files}}"
  }
```

- [ ] **Step 5: Test wiring.** In `assets/mise.toml`, the `test` task's `all)` branch becomes:

```bash
  all)
    mise run test bin
    mise run integration backup all
    ;;
```

- [ ] **Step 6: Verify.**

```bash
cd ~/Work/dots-backup
mise tasks --global 2>/dev/null | grep -E '^(backup|reinstall)' || mise -C "$PWD/config/mise" tasks | grep -E 'backup|reinstall'
mise run -C assets integration hooks all
mise run -C assets test all
hk check --all 2>&1 | tail -5
HOMEBREW_DOTS_PROFILE=desktop brew bundle list --file config/homebrew/Brewfile | grep -x restic
```

  Expected: six tasks listed (from `~/Work/dots`'s linked config once merged; in the worktree the second form
  lists them); hook specs pass (if a spec asserts the exact step list, add `taplo-schema` to it); `test all`
  green; hk clean; `restic` printed.

- [ ] **Step 7: Commit.**

```bash
g add config/mise/conf.d/backup.toml config/mise/config.toml config/homebrew/Brewfile hk.pkl assets/mise.toml
g commit -m "feat(backup): Add backup and reinstall tasks; validate the manifest schema in hk

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6: The guide

**Files:** create `assets/guides/REINSTALL_GUIDE.md`.

Write it for the owner reading it months from now, with no memory of this work. Every section below is
required (R10). Commands must be copy-paste ready and match the code as built. Use tables for references and
checkboxes for the playbook.

- [ ] **Step 1: Write the file** with this front matter and these sections, in order:

```markdown
---
title: Reinstall and backup guide
description: Back up, wipe, reinstall and restore a Mac with dots; the backup drive layout and the backup manifest
---
<!-- markdownlint-disable-file -->

# Reinstall and backup guide

> Last reviewed: <today, YYYY-MM-DD>
```

  1. **Purpose.** What the guide covers (a clean macOS reinstall, routine backups), what it does not (Linux:
     README Install; Time Machine: optional extra), and the two-line summary: *dots restores config, packages
     and secrets; restic restores your data.*
  2. **What comes back from where.** Table: Config and dotfiles → `install` (this repo); packages → Brewfile;
     secrets (ssh, gpg, sops, gopass) → `dots-history` with the age key; agent skills → `skills:restore`; oMLX
     models, toolchains, caches → re-downloaded; your data (`~/Work`, `~/Documents`, …) → restic; the age key and
     restic password → your password manager **only**. Explain why: this is why the excludes can be so broad.
  3. **Terms.** Table defining: backup root, restic repository, snapshot, tag, export, reinstall audit,
     `MANIFEST.md`, backup manifest (`config/restic/backup.toml`), schema, exclude pattern, retention policy,
     prune, host name (`LocalHostName`), 3-2-1 rule, Full Disk Access.
  4. **Drive layout.** The tree from design §2, then a table: each folder, what goes in it, why it exists.
     Conventions and why: host first (one drive, several machines); ISO 8601 extended dates (sort as text, read
     unambiguously); `media/` kept apart (not restored by tasks); `archive/` for retired hosts; the drive
     `README.md` (readable without this repo). Include the one-time migration of the existing drive:

     ```sh
     B=/Volumes/backups; H=$(scutil --get LocalHostName)
     mkdir -p "$B/machines/$H/exports/2026-11-04/legacy" "$B/media" "$B/archive"
     mv "$B/20261104/"* "$B/machines/$H/exports/2026-11-04/legacy/" && rmdir "$B/20261104"
     mv "$B/popcorn" "$B/media/"
     ```

  5. **The manifest.** Show the head of `config/restic/backup.toml`; a table of every key (type, default,
     meaning, why), copied from design §3; the full exclude list as a table (pattern, why); how `~` and
     `{host}` expand; restic pattern rules in brief (`**` any depth, a leading path anchors, no `~` expansion by
     restic itself, hence the script does it); **how to add an exclude** (append an `[[exclude]]` with
     `pattern` and `why`, then `taplo check config/restic/backup.toml`); **how it is validated** (`#:schema`,
     `taplo check` in hk `taplo-schema`, at run time, editor completion); why TOML + JSON Schema (same format as
     the rest of dots, taplo already installed, every exclusion carries its reason); why restic gets a
     generated exclude file.
  6. **Tasks.** One subsection per task (`reinstall:audit`, `backup:init`, `backup`, `backup:snapshots`,
     `backup:restore`, `backup:forget`): what it does, flags, an example, exit codes (0 ok; 1 setup error such
     as a missing root or repository; 2 usage error; 3 from `backup` when some files were unreadable; other
     codes are restic's), and what it never does (no task creates or prints a password; audit changes nothing
     outside its export folder). Then the environment variables table: `DOTS_BACKUP_ROOT`, `DOTS_BACKUP_HOST`,
     `DOTS_BACKUP_MANIFEST`, `RESTIC_PASSWORD`, `RESTIC_PASSWORD_FILE`, `RESTIC_PASSWORD_COMMAND` (empty
     means "prompt"). Note that extra arguments go after `--`: `mise run backup:restore -- --include Work`.
  7. **First-time setup** (once per machine): `brew install restic` (or `brew bundle install`), grant the
     terminal Full Disk Access (System Settings → Privacy & Security → Full Disk Access), `gopass generate
     backups/restic 32`, copy that password into the password manager, `mise run backup:init`, `mise run
     backup`, a test restore into a temp folder:

     ```sh
     mise run backup:restore -- --include Documents --target "$(mktemp -d)"
     ```

  8. **Reinstall playbook.** Checklists with snippets, per phase:
     - **T-7 days:** `mise run reinstall:audit`; open `MANIFEST.md`; push or add remotes for every repo it
       flags; decide on large non-git folders (keep in the snapshot, or exclude with a `why`); `brew bundle
       add` anything in `apps.txt` you want back; clear old stashes and squash-merged branches.
     - **T-1 day:** secrets you cannot get back into the password manager (age key, restic password, 2FA
       recovery codes, licence keys); browser sync on; `mise run backup`; `mise run backup:snapshots`; a test
       restore; `mise run reinstall:audit` again for the final record; note the host and user from
       `MANIFEST.md`.
     - **Wipe:** sign out of iCloud (turns off Find My and Activation Lock), sign out of the App Store and
       Music, unpair Bluetooth devices you will reuse, then System Settings → General → Transfer or Reset →
       Erase All Content and Settings. Eject and unplug the backup drive first.
     - **Reinstall:** Setup Assistant (use the same short user name if you can; turn FileVault on), then
       `xcode-select --install`, then the `install` one-liner from the README, then `brew trust` for each tap
       the audit flagged and `brew bundle install`.
     - **Restore:** plug the drive in; dry run first, then for real, data folders only:

       ```sh
       DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work --include Documents --dry-run
       DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work --include Documents
       ```

       Never restore `.config`, `.ssh`, `.gnupg`, `.local` or `Library` wholesale: `install` already created
       them as links into dots; restoring them breaks the links.
     - **Verify:** `brew bundle check`, `mise bootstrap status --missing`, `gopass ls`, `gh auth status`,
       `mise dot status`, open each restored repo (`git status`); then `mise run backup:init` for the new host
       name if it changed (or keep `DOTS_BACKUP_HOST`), and a first `mise run backup`.
     - **T+1 week:** turn on Time Machine if wanted; `mise run backup:forget`; move the old host folder to
       `archive/` once you are sure.
  9. **Recovery without gopass.** If `install` has not restored gopass yet: `RESTIC_PASSWORD_COMMAND=
     DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work` prompts for the password (from the
     password manager). Without dots at all: the plain `restic` command from the drive `README.md`.
  10. **Heads-ups.** Each with why and what to do: the drive is unencrypted (restic data is encrypted; anything
      in `exports/legacy/` is not, so do not put tokens there unencrypted); Full Disk Access (exit 3); host name
      changes after reinstall (`DOTS_BACKUP_HOST`); cloud folders are excluded on purpose; repositories without a
      remote; large non-git folders (`~/Work/rust` was 56 GB); the untrusted `can1357/tap`; keychain items,
      browser profiles, Mail and Messages are not in dots (Mail and Messages are in the snapshot only with Full
      Disk Access); HFS+ is fine for restic; restic locks (`restic unlock` after an interrupted run); a full
      drive (`backup:forget`).
  11. **Best practices.** Test a restore after every first backup and every few months; 3-2-1 (this drive is
      one copy; add one off-site, e.g. a second restic repository with `restic copy`); back up before big
      changes; keep the age key and restic password in the password manager and nowhere unencrypted; run the
      audit before any wipe; give every exclude a reason; keep the retention short enough for the drive.
  12. **Troubleshooting.** Table: symptom → cause → fix, for: `backup root not found`; `no repository at`;
      `password command failed`; `wrong password or no key found`; `repository is already locked`; exit 3;
      `manifest fails its schema`; restore wrote nothing (wrong `--from-home` or include; use `--dry-run`).
  13. **See also.** README (Install, Day to day), `config/restic/backup.toml`, `script/backup.ts`,
      `assets/specs/reinstall-backup/`, restic docs (https://restic.readthedocs.io).

- [ ] **Step 2: Check it against the code.** Every command in the guide runs as written in the worktree
  (use `DOTS_BACKUP_ROOT="$(mktemp -d)"`, `DOTS_BACKUP_HOST=test`, `RESTIC_PASSWORD=x` and
  `bun script/backup.ts …` in place of the mise task where needed); every exclude in the guide's table matches
  `config/restic/backup.toml` (`diff <(taplo get -f config/restic/backup.toml 'exclude.*.pattern') <(…)`).

- [ ] **Step 3: Commit.**

```bash
g add assets/guides/REINSTALL_GUIDE.md
g commit -m "docs(guides): Add the reinstall and backup guide

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7: Glossary, guide index, README

- [ ] **Step 1: `assets/guides/GLOSSARY.md`** — add rows to the Terms table:

```markdown
| Backup root | The folder holding all backups, `/Volumes/backups` by default; `DOTS_BACKUP_ROOT` overrides. |
| Backup manifest | `config/restic/backup.toml`: what to back up, where, retention and excludes, validated by `backup.schema.json`. |
| restic repository | The encrypted, deduplicated store at `<backup root>/machines/<host>/restic`. |
| Snapshot | One backup run in a restic repository, tagged with the host. |
| Export | A dated folder under `machines/<host>/exports/` holding an audit and one-off copies. |
| Reinstall audit | `mise run reinstall:audit`: a read-only report of what a reinstall would lose (`MANIFEST.md`). |
```

- [ ] **Step 2: `assets/guides/README.md`** — add a row:

```markdown
| `REINSTALL_GUIDE.md` | Back up, wipe, reinstall and restore a Mac; backup drive layout; the backup manifest |
```

- [ ] **Step 3: `README.md`** — in `## Day to day`, after `### Secrets`, add:

````markdown
### Back up

```sh
mise run backup                                   # home folder → restic on /Volumes/backups, then check
mise run backup:restore -- --include Work --dry-run
mise run reinstall:audit                          # before a wipe: what would be lost
```

The policy is [`config/restic/backup.toml`](config/restic/backup.toml); the full playbook is
[`assets/guides/REINSTALL_GUIDE.md`](assets/guides/REINSTALL_GUIDE.md).
````

  And in `## Playbooks`, add a line or row (matching the section's format) pointing to the guide as
  "Reinstall a Mac".

- [ ] **Step 4: Check and commit.**

```bash
cd ~/Work/dots-backup
hk check --all 2>&1 | tail -3
g grep -n 'meex900' -- . ':!CHANGELOG.md' ':!assets/specs'   # expect nothing
g add assets/guides/GLOSSARY.md assets/guides/README.md README.md
g commit -m "docs: Point to the reinstall guide from the README, glossary and guide index

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Final gate

- [ ] `mise run -C assets test all` → green; `bun test` under `assets/integration/backup/` → no skips on this Mac.
- [ ] `hk check --all` → clean.
- [ ] `bun script/backup.ts audit --stdout | head -40` → a real report for this Mac (read-only; check that it
  lists `carrie` and `essay` with `no remote`, and `can1357/tap` as untrusted).
- [ ] `g log --oneline main..` → the commits of Tasks 2–7. Report to the owner; do not push or open a PR
  unless asked.

### Task 9: Owner steps (not for the agent)

On the owner's go: merge, then on this Mac `mise run backup:init` (after `gopass generate backups/restic 32`
and saving it to the password manager), the drive migration snippet from the guide, `mise run
reinstall:audit`, `mise run backup`, a test restore. Then the reinstall playbook.
