<!-- markdownlint-disable -->
# Reinstall and backup — requirements

## Context (scan of this Mac, 2026-11-04)

| Finding | Evidence |
| --- | --- |
| No system backup | `tmutil destinationinfo`: no destinations; FileVault off |
| The backup drive is ad hoc | `/Volumes/backups` (2 TB, HFS+, unencrypted) holds `20261104/` (5 zips) and `popcorn/` (media) |
| The existing `backup` task is a scratch script | `config/mise/config.toml [tasks.backup]` zips `~/Work` to `/Volumes/meex900/…` with hard-coded paths |
| Secrets already round-trip through dots | `~/.ssh`, `~/.gnupg`, `~/.config/sops` link into the dots repo; `install` restores them from `dots-history` with the age key |
| Some work exists only on this disk | `carrie` (90 dirty, 1 unpushed, no remote), `essay` (14 dirty, 31 unpushed, no remote), `dots` (13 stashes, 213 commits on local-only branches) |
| Most of `~` is re-downloadable | `~/.omlx` 14 GB, `~/.cache` 11 GB, mise/cargo/uv/nvim data ≈ 9 GB; `~/Work` 68 GB, of which `rust` is 56 GB (not git) |
| A Brewfile tap is untrusted | `brew bundle cleanup` refuses `can1357/tap` until `brew trust can1357/tap` |

## User stories

1. As the owner, before a clean macOS reinstall I run one read-only audit that tells me what would be lost.
2. As the owner, I back up my home folder to the external drive, encrypted and deduplicated, with one command,
   and verify it.
3. As the owner, after the reinstall and `install`, I restore only my data (not dotfiles or caches) with one command.
4. As the owner, I follow one guide that explains every step, term, setting and reason, for this and future
   reinstalls.
5. As the owner, the drive has a layout I can understand without the guide.

## Requirements (EARS)

| ID | Requirement |
| --- | --- |
| R1 | The backup policy SHALL live in one TOML manifest, `config/restic/backup.toml`, validated by a JSON Schema, `config/restic/backup.schema.json`. |
| R2 | WHEN a manifest key is unknown, or an exclude has no `why`, the pre-commit hook and the tasks SHALL reject the manifest. |
| R3 | The tool SHALL use restic; the repository SHALL be at `<root>/machines/<host>/restic`. |
| R4 | WHEN the backup root does not exist, every task except `reinstall:audit --stdout` SHALL exit 1 and name the missing path and `DOTS_BACKUP_ROOT`. |
| R5 | `reinstall:audit` SHALL change nothing outside `<root>/machines/<host>/exports/<YYYY-MM-DD>/` and SHALL report repos that are dirty, unpushed, stashed or without a remote; non-git folders in `~/Work`; Brewfile drift; apps not declared as casks; FileVault and Time Machine status; the largest folders in `~`. |
| R6 | `backup` SHALL back up the manifest's paths minus its excludes, tag the snapshot with the host, then run `restic check`. |
| R7 | `backup:restore` SHALL require at least one `--include`, SHALL restore paths relative to the old home into the new home, and SHALL support `--dry-run`. |
| R8 | `backup:forget` SHALL apply the manifest's retention and prune. |
| R9 | The restic password SHALL come from `repository.password_command` (gopass) unless `RESTIC_PASSWORD`, `RESTIC_PASSWORD_FILE` or `RESTIC_PASSWORD_COMMAND` is set; no task SHALL create or print a password. |
| R10 | `assets/guides/REINSTALL_GUIDE.md` SHALL document every term, manifest key, task, flag, drive folder, phase, heads-up and the reason for each. |
| R11 | `mise run -C assets test all` and the linters SHALL stay at zero warnings and errors. |

## Out of scope

Linux desktops (one pointer to the README), Time Machine automation, off-site copies (documented as a best
practice only), encrypting the drive (the owner keeps it as is; restic data is encrypted), scheduled backups.
