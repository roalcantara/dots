# Backup allowlist — design

Status: approved by the owner (2026-11-06).

## Problem

`mise run backup` reads all of `~` minus a deny list: 606,863 files, 541 GiB (Parallels VMs in `~/.local/state`,
Downloads, app data). The backup should hold only files with no other source: no git remote, dots, Homebrew,
iCloud or app sync.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Selection | Conservative allowlist (owner review of a per-folder inventory, 2026-11-06): personal folders, `~/.config`, real shell files, every credential, agent memory and settings, tool settings, `~/Library/Preferences` and other macOS customization | First tested pass: keep anything that is a setting, customization or secret; leave out caches, binaries, models, VMs, worktrees |
| Out | The rest of `~/.local` and `~/Library`, `~/Downloads`, `~/Movies`, `~/Music`, tool payloads (models, extensions, caches, logs), worktrees | Rebuilt, re-downloaded, synced or disposable |
| Excludes | Junk inside the allowlist (`node_modules`, `target`, `.venv`, …), agent caches and logs, worktrees, `~/Work/mydemon/inspiration`. `.gitignore` is not mirrored | Some secrets exist only as git-ignored files |
| Restore home | `backup` tags each snapshot `home:<home>`; `restore` reads it, else the single-path rule (old snapshots) | With several paths, the old home can no longer be inferred |
| Drive | Delete the partial `machines/<host>/restic` (no snapshot), `backup:init` again; other folders stay | The interrupted run left 34 GiB that no snapshot owns |

## Done when

- `hk check` and the `backup` spec domain pass.
- A real `mise run backup` (branch manifest) finishes, `restic check` passes, the snapshot holds the allowlisted roots and
  no `target/`, `node_modules/` or `inspiration/`; `backup:restore --include Documents --dry-run` maps to `~/Documents`.
