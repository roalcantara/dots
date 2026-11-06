# Backup allowlist — implementation plan

Spec: [`docs/superpowers/specs/2026-11-06-backup-allowlist-design.md`](../specs/2026-11-06-backup-allowlist-design.md).
Worktree `~/Work/dots-backup`, branch `feat/backup-allowlist`. Git via the SOPS wrapper; named paths only.

- [ ] **Task 1 (TDD):** `homeFromSnapshot({paths, tags})` in `script/backup.ts`; `backupArgs` adds `--tag home:<home>`.
  Specs: unit cases (tag, single path, several paths without tag) and the e2e test with two paths restoring
  without `--from-home`.
- [ ] **Task 2:** `config/restic/backup.toml`: allowlist paths, in-tree excludes only, `inspiration` exclude.
- [ ] **Task 3:** `docs/REINSTALL.md`: §2, §5 (manifest, excludes), restore notes.
- [ ] **Task 4:** Gates: `hk check`, `mise run test:specs` (backup domain green; pre-existing `xc-git` failures noted).
- [ ] **Task 5 (owner-approved):** delete `/Volumes/backups/machines/<host>/restic`, `bun script/backup.ts init`,
  `bun script/backup.ts backup` from the worktree, then verify per the spec's "Done when".
- [ ] **Task 6:** Commit, push, open the PR.
