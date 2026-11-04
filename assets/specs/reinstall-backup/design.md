<!-- markdownlint-disable -->
# Reinstall and backup — design

Requirements: [requirements.md](requirements.md). Owner decisions (2026-11-04): restic plus a manual export
area; the drive stays HFS+ and unencrypted; a guide plus mise tasks; macOS only; the policy is a TOML manifest
with a JSON Schema.

## 1. Approaches

| | Tool | For | Against | Verdict |
| --- | --- | --- | --- | --- |
| A | restic | Widely adopted; encrypted and deduplicated; dated, tagged snapshots; `check`, `restore`, `forget` built in; one Homebrew formula | Needs a password | **Chosen** |
| B | Kopia | GUI, policies, compression | Less common; policy lives inside the repository | Rejected |
| C | rsync dated copies | No new tool | No dedup, no encryption, full copy per run | Rejected |

restic matters more because the drive stays unencrypted: a restic repository is encrypted at rest.

## 2. Drive layout

Host first, ISO 8601 extended dates (`YYYY-MM-DD`, sorts and reads), media apart from machines:

```text
/Volumes/backups/                 DOTS_BACKUP_ROOT
├── README.md                     written by backup:init if absent: what is here, how to restore
├── machines/
│   └── <host>/                   scutil --get LocalHostName, or DOTS_BACKUP_HOST
│       ├── restic/               the restic repository
│       └── exports/
│           └── YYYY-MM-DD/       one folder per audit (reinstall)
│               ├── MANIFEST.md   the audit report
│               ├── brew-leaves.txt, brew-casks.txt, brew-bundle-check.txt, apps.txt, mas.txt, repos.tsv
│               └── legacy/       one-off copies (today: the 20261104 zips)
├── media/                        not machine backups (today: popcorn/)
└── archive/                      retired machines, moved whole from machines/
```

## 3. The manifest

`config/restic/backup.toml`, first line `#:schema ./backup.schema.json`:

| Key | Type | Default in file | Meaning |
| --- | --- | --- | --- |
| `repository.root` | string | `/Volumes/backups` | Backup root; `DOTS_BACKUP_ROOT` overrides |
| `repository.path` | string | `machines/{host}/restic` | Repository, relative to the root; `{host}` expands |
| `repository.password_command` | string | `gopass show -o backups/restic` | Becomes `RESTIC_PASSWORD_COMMAND` unless a restic password variable is set |
| `backup.paths` | string[] (≥1) | `["~"]` | What to back up; `~` expands to `$HOME` |
| `backup.tags` | string[] | `["{host}"]` | Snapshot tags |
| `backup.exclude_caches` | bool | `true` | Passes `--exclude-caches` (skips folders with a `CACHEDIR.TAG`) |
| `retention.daily`, `.weekly`, `.monthly` | int ≥ 0 | 7, 4, 12 | `restic forget --keep-*`; 0 omits the flag |
| `[[exclude]]` `pattern` | string (non-empty) | — | A restic exclude pattern; `~` and `{host}` expand |
| `[[exclude]]` `why` | string (non-empty) | — | The reason; required so every exclusion is justified |

The schema (`config/restic/backup.schema.json`, draft-07) sets `additionalProperties: false` at every level,
requires `repository.path`, `backup.paths`, and `pattern` + `why` per exclude.

Who checks it:

- `taplo check` honors `#:schema` (verified 2026-11-04 with taplo 0.10.0: a missing `why` fails with
  `"why" is a required property`). A new hk step `taplo-schema` runs it on `config/restic/*.toml` at pre-commit.
- The script runs `taplo check` on the manifest before any restic call when `taplo` is on `PATH`.
- Editors with Even Better TOML complete keys from the directive.

restic reads only a plain exclude file, so the script writes the expanded patterns to a temporary file and
passes `--exclude-file`; the file is never committed.

Initial excludes (each with its `why` in the file): `~/.cache`, `~/Library/Caches`, `~/.Trash`,
`~/Library/CloudStorage` (cloud drives; reading them downloads everything), `~/Library/Mobile Documents`
(iCloud Drive), `~/.omlx`, `~/.local/share/mise`, `~/.local/share/cargo`, `~/.local/share/rustup`,
`~/.local/share/uv`, `~/.local/share/nvim`, `~/Library/Developer/Xcode/DerivedData`,
`~/Library/Developer/CoreSimulator`, `~/Library/Containers/com.docker.docker`, `~/.orbstack`,
`**/node_modules`, `**/target`, `**/.gradle`, `**/.venv`, `**/__pycache__`, `**/.DS_Store`.
`~/Work/dots` is **not** excluded: its stashes and local branches exist only here.

## 4. `script/backup.ts`

Bun, same shape as `script/agent-skills.ts`: exported pure functions (unit-tested) and a `main` that runs
commands.

| Function | Pure | Does |
| --- | --- | --- |
| `parseManifest(text)` | ✓ | `Bun.TOML.parse`, returns a typed `Manifest`; throws on a missing required key |
| `expand(s, ctx)` | ✓ | Leading `~` → `ctx.home`; `{host}` → `ctx.host` |
| `repoPath(m, ctx)` | ✓ | `join(ctx.root, expand(m.repository.path))`; `ctx.root` = `DOTS_BACKUP_ROOT` ?? `m.repository.root` |
| `excludeLines(m, ctx)` | ✓ | Expanded patterns, one per line |
| `passwordEnv(m, env)` | ✓ | `{RESTIC_PASSWORD_COMMAND}` unless a restic password variable is already set, else `{}` |
| `backupArgs(m, ctx, excludeFile)` | ✓ | `backup <paths…> --exclude-file F [--exclude-caches] --tag T…` |
| `forgetArgs(m)` | ✓ | `forget --keep-daily N … --prune`, zeros omitted |
| `restoreArgs(o)` | ✓ | `restore <snapshot>:<fromHome> --target <home> --include /<p>… [--dry-run]` |
| `classifyRepo(s)` | ✓ | From `{dirty, unpushed, stashes, remotes}` returns risk strings (`no remote`, `3 unpushed`, …) |
| `renderManifest(facts)` | ✓ | The `MANIFEST.md` text: header, risks first, then each section, then the checklist |
| `collectFacts(ctx)` | — | Runs `git`, `brew`, `fdesetup`, `tmutil`, `du`, `mas` (each optional; a missing tool is reported, not fatal) |

Commands: `audit [--stdout]`, `init`, `backup`, `snapshots`, `restore --include P… [--snapshot ID]
[--from-home DIR] [--dry-run]`, `forget`. Context: `HOME`, host (`DOTS_BACKUP_HOST` ?? `scutil --get
LocalHostName` ?? `os.hostname()` up to the first dot), root, manifest path (`DOTS_BACKUP_MANIFEST` ??
`<script dir>/../config/restic/backup.toml`).

Behavior:

- **Root missing** → exit 1: `backup root not found: <root> (mount the drive or set DOTS_BACKUP_ROOT)`.
  `audit --stdout` is the one command that works without it.
- **`init`**: refuses if `<repo>/config` exists (already initialized, exit 0 with a note). Checks the password
  source first; if `password_command` fails, exits 1 with `create it: gopass generate backups/restic 32` (it
  never creates a secret). Runs `restic init`, creates `exports/`, writes `<root>/README.md` if absent.
- **`backup`**: restic exit 3 (some files unreadable) is reported as a warning naming Full Disk Access, and the
  task still runs `restic check`, then exits 3. Other non-zero codes pass through.
- **`restore`**: no `--include` → exit 2 with usage. `--from-home` defaults to the snapshot's original home:
  read from `restic snapshots --json` (the snapshot's only path; with several paths, `--from-home` is required). The
  `<snapshot>:<subfolder>` syntax needs restic ≥ 0.17, checked at start.
- **`audit`**: writes `exports/<today>/`, prints the path and the risk count; never exits non-zero for risks.

## 5. mise tasks

`config/mise/conf.d/backup.toml` (global config, so they run from any folder), each
`tools = { bun = "1.3.14" }` and `run = 'bun "$HOME/.local/share/dots/script/backup.ts" <cmd>'`; extra
arguments pass through after `--`:

| Task | Command |
| --- | --- |
| `reinstall:audit` | `audit` |
| `backup:init` | `init` |
| `backup` | `backup` |
| `backup:snapshots` | `snapshots` |
| `backup:restore` | `restore` |
| `backup:forget` | `forget` |

The scratch `[tasks.backup]` in `config/mise/config.toml` is removed. The Brewfile gets `brew "restic"` in the
desktop core formulae.

## 6. The guide

`assets/guides/REINSTALL_GUIDE.md` is the user-facing source of truth and must hold every definition,
rationale and usage (R10):

1. Purpose and when to use it.
2. Terms (backup root, restic repository, snapshot, export, audit, manifest, retention, 3-2-1).
3. Drive layout, with why each folder exists and the naming conventions.
4. The manifest: every key, its default and why; how to add an exclude; how it is validated.
5. Tasks: each task, its flags, an example and its exit codes.
6. The reinstall playbook in phases (T-7 days, T-1 day, wipe, reinstall, restore, T+1 week), each a
   checklist with snippets.
7. Recovery without gopass (password from the password manager).
8. Heads-ups (unencrypted drive, Full Disk Access, host name change, cloud folders, repos without remotes,
   large non-git folders, untrusted tap, keychain and browser data outside dots).
9. Best practices (test restores, 3-2-1, retention, run after big changes, keep the age key and restic
   password in the password manager).
10. Troubleshooting (locks: `restic unlock`; wrong password; drive not mounted; exit 3).

Also: GLOSSARY terms, an entry in `assets/guides/README.md`, a README Day-to-day row.

## 7. Testing

`assets/integration/backup/backup.spec.ts` (`mise run -C assets integration backup`):

- Unit: every pure function in §4, including the repository manifest itself parsing and every exclude having a
  `why`.
- Schema: `taplo check` passes on the repository manifest and fails on a fixture without `why` and one with an
  unknown key (skipped if `taplo` is missing).
- End to end (skipped if `restic` is missing): a temp root and fake `HOME` with `docs/a.txt` and
  `node_modules/x`; `RESTIC_PASSWORD=test`; `init` → `backup` → `snapshots` shows one → `restore --include docs`
  into a second fake home restores `docs/a.txt` and not `node_modules`.
- Errors: missing root exits 1 with the message; `restore` without `--include` exits 2.

## 8. Risks

| Risk | Mitigation |
| --- | --- |
| Host name differs after reinstall, so `{host}` points at a new empty repo | `DOTS_BACKUP_HOST=<old>`; the guide says to note the old name in the audit (MANIFEST.md records it) |
| gopass is not restored yet when restoring | The guide's recovery section: `RESTIC_PASSWORD_COMMAND= mise run backup:restore …` prompts for the password from the password manager |
| restic lacks Full Disk Access and skips TCC folders | Exit 3 is reported with the fix; the guide covers granting it |
| `taplo check` fetches remote schemas for other files | The hk step is scoped to `config/restic/*.toml` |
| `restore` overwrites files `install` created | `--include` is required and the guide restores data folders only |
