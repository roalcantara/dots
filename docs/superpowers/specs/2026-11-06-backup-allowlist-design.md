# Backup allowlist — design

Status: approved by the owner (2026-11-06).

## Problem

`mise run backup` reads all of `~` minus a deny list: 606,863 files, 541 GiB (Parallels VMs in `~/.local/state`,
Downloads, app data). The backup should hold only files with no other source: no git remote, dots, Homebrew,
iCloud or app sync.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Selection | Allowlist: `paths = ["~/Documents", "~/Desktop", "~/Private", "~/Work"]` | Smallest; new folders stay out until added |
| Out | `~/.local`, `~/Library`, `~/Downloads`, `~/Pictures`, `~/Movies`, `~/Music`, tool dot-folders (`~/.android`, `~/.claude`, `~/.omp`, …) | Rebuilt by tools, synced, or disposable (owner, 2026-11-06) |
| Excludes | Only junk inside the allowlist: `node_modules`, `target`, `.gradle`, `.venv`, `__pycache__`, `.DS_Store`, plus `~/Work/mydemon/inspiration` | Home-level excludes no longer match anything |
| Restore home | `backup` tags each snapshot `home:<home>`; `restore` reads it, else the single-path rule (old snapshots) | With several paths, the old home can no longer be inferred |
| Drive | Delete the partial `machines/<host>/restic` (no snapshot), `backup:init` again; other folders stay | The interrupted run left 34 GiB that no snapshot owns |

## Done when

- `hk check` and the `backup` spec domain pass.
- A real `mise run backup` (branch manifest) finishes, `restic check` passes, the snapshot holds the four roots and
  no `target/`, `node_modules/` or `inspiration/`; `backup:restore --include Documents --dry-run` maps to `~/Documents`.
