---
title: Reinstall and backup guide
description: Back up, wipe, reinstall and restore a Mac with dots; the backup drive layout and the backup manifest
---
<!-- markdownlint-disable-file -->

# Reinstall and backup guide

> Last reviewed: 2026-11-06

## 1. Purpose

This guide provides instructions for routine backups, clean macOS reinstalls, and machine migrations using dots and restic.

- **What it covers:** Clean macOS reinstalls, routine encrypted backups to external storage, verifying backups, and restoring data into a freshly provisioned system.
- **What it does not cover:** Linux installations (see repo root `README.md` for Linux installation instructions) or Time Machine configuration (Time Machine is an optional extra, not managed by dots).

> *dots restores config, packages and secrets; restic restores your data.*

---

## 2. What comes back from where

| Component                       | Source / Mechanism                             | Details                                                                                                                                                                 |
| ------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Config and dotfiles**         | `install` (this repo)                          | Symlinked from `~/.local/share/dots` into `$HOME` (`~/.config`, `~/.zshrc`, etc.).                                                                                      |
| **Packages and tools**          | Homebrew Brewfile (`config/homebrew/Brewfile`) | CLI binaries, GUI casks, and language toolchains installed via `brew bundle`.                                                                                           |
| **Secrets and keys**            | `dots-history` via age key                     | Encrypted repository holding SSH and GPG keys; gopass, gh and wakatime secrets are SOPS-encrypted in this repo (`config/<app>`).                                        |
| **Agent skills**                | `skills:restore` (background)                  | Agent skills declared in `config/agents/skill-lock.json`, restored in parallel in the background.                                                                       |
| **Models and caches**           | Re-downloaded on demand                        | oMLX models, rustup toolchains, uv Pythons, and mise runtimes reinstalled cleanly.                                                                                      |
| **Personal data and settings**  | restic backup repository                       | An allowlist (`backup.paths`): personal folders, `~/.config`, shell files, credentials, agent memory and settings, macOS preferences. Nothing else in `~` is backed up. |
| **Age key and restic password** | Password manager **only**                      | Stored in 1Password / Bitwarden; the only two secrets dots cannot restore.                                                                                              |

### Why an allowlist

dots, Homebrew and lock files rebuild tools, caches and configuration; iCloud, browser sync and the apps themselves
restore their own data. So restic backs up a list of named paths (`backup.paths`) instead of excluding what is not
wanted from all of `~`. A full-home run read 606,863 files (541 GiB, mostly Parallels VMs in `~/.local/state`).

The list is conservative: everything personal, every setting or customization, and every credential, even where
another copy exists (dots, a git remote, a cloud account). It leaves out what a tool can download or rebuild.

| Backed up                                                                                                                                                                     | Why                                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `~/Documents`, `~/Desktop`, `~/Private`, `~/Pictures`, `~/Work`                                                                                                               | Personal files; repos without a remote, uncommitted and unpushed work                              |
| `~/.config`, small `~/.local/{share,state}` folders (zsh history, gopass store, posting, television, gh)                                                                      | XDG config; dots links are stored as links, `~/.config/ssh` and `~/.config/gnupg` are real folders |
| `~/.zshrc`, `~/.zprofile`, `~/.gitconfig`, shell histories                                                                                                                    | Real files, not dots links: installers write to them                                               |
| Credentials: `~/.aws`, `~/.claude.json`, `~/.codex/auth.json`, Gemini, Docker, gsutil, LocalStack, Streamlit, Serverless, Android keys, `~/Library/Keychains`, AWS VPN Client | Just in case; restic encrypts the repository                                                       |
| Agents: `~/.claude`, `~/.omp`, `~/.agents`, and the settings of Codex, Gemini, Cursor, Copilot, Kiro and other agent tools                                                    | Memory, sessions, settings, hooks, MCP servers                                                     |
| Tool settings: LM Studio, oMLX, VS Code `argv.json`, small rc files                                                                                                           | Settings only; not the models or extensions                                                        |
| `~/Library/Preferences`, `LaunchAgents`, `Services`, `Spelling`, `Sounds`, `DBeaverData`, Raycast's backups, VS Code MCP, Claude desktop config                               | macOS and app settings with no other copy                                                          |

| Not backed up                                                                               | Comes back from                               |
| ------------------------------------------------------------------------------------------- | --------------------------------------------- |
| The rest of `~/.local` (tool installs, VMs)                                                 | `mise bootstrap`; VMs are rebuilt             |
| The rest of `~/Library` (app data, caches, containers)                                      | The apps, iCloud and their own sync           |
| `~/Downloads`, `~/Movies`, `~/Music`                                                        | Disposable, or synced (Apple TV, Apple Music) |
| Tool payloads: models (`~/.omlx/models`), extensions (`~/.vscode/extensions`), caches, logs | The tools download or rebuild them            |
| Worktrees (`~/Work/dots-*`, `**/.claude/worktrees`)                                         | Their commits live in the main repository     |

A new folder is **not** backed up until it is added to `backup.paths`.

restic cannot read `.gitignore`, so git-ignored files are backed up unless an exclude pattern matches them. That is
deliberate: some secrets exist only as ignored files (`~/Work/dots/config/age/keys.txt`, `config/gh/hosts.yml`).

---

## 3. Terms

| Term                            | Definition                                                                                                                     |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **Backup root**                 | The folder holding all backups, `/Volumes/backups` by default; overridden by `DOTS_BACKUP_ROOT`.                               |
| **restic repository**           | The encrypted, deduplicated restic storage located at `<backup root>/machines/<host>/restic`.                                  |
| **Snapshot**                    | One point-in-time backup run in a restic repository, tagged with the machine host name.                                        |
| **Tag**                         | A label attached to restic snapshots, defaults to `{host}` (e.g. `Mac`).                                                       |
| **Export**                      | A dated folder under `machines/<host>/exports/` holding an audit report and one-off copies.                                    |
| **Reinstall audit**             | `mise run reinstall:audit`: a read-only assessment of unpushed git state, non-cask apps, and machine risk (`MANIFEST.md`).     |
| **`MANIFEST.md`**               | The comprehensive markdown report generated by `reinstall:audit`.                                                              |
| **Backup manifest**             | `config/restic/backup.toml`: defines repository path, source paths, retention policy, and exclusions with reasons.             |
| **Schema**                      | `config/restic/backup.schema.json`: JSON Schema draft-07 validating manifest structure and requiring exclusion justifications. |
| **Exclude pattern**             | A path or glob skipped during restic backups; each entry requires a `why` justification.                                       |
| **Retention policy**            | Rules declaring how many daily, weekly, and monthly snapshots restic keeps during pruning.                                     |
| **Prune**                       | Deleting unreferenced data blobs from the restic repository to reclaim disk space after `forget`.                              |
| **Host name (`LocalHostName`)** | Machine identifier obtained via `scutil --get LocalHostName` or `DOTS_BACKUP_HOST`.                                            |
| **3-2-1 rule**                  | Backup best practice: 3 copies of data, across 2 different storage media, with 1 copy stored off-site.                         |
| **Full Disk Access**            | macOS permission enabling the terminal to read protected directories (e.g. Mail, Messages, Safari data).                       |

---

## 4. Drive layout

The backup drive organizes machines by host name, uses ISO 8601 extended dates (`YYYY-MM-DD`), and separates generic media from system backups:

```text
/Volumes/backups/                 DOTS_BACKUP_ROOT
├── README.md                     Written by backup:init if absent: drive overview and restore instructions
├── machines/
│   └── <host>/                   scutil --get LocalHostName, or DOTS_BACKUP_HOST
│       ├── restic/               The encrypted restic repository
│       └── exports/
│           └── YYYY-MM-DD/       One dated folder per reinstall audit
│               ├── MANIFEST.md   Audit summary report
│               ├── apps.txt      Applications found in /Applications
│               ├── brew-bundle-check.txt
│               ├── brew-bundle-cleanup.txt
│               ├── brew-casks.txt
│               ├── brew-leaves.txt
│               ├── mas.txt       Mac App Store applications
│               ├── repos.tsv     Tab-separated git repository status (dirty, unpushed, stashed)
│               └── legacy/       One-off copies and archives
├── media/                        External media files not tied to machine backups
└── archive/                      Decommissioned machines moved whole from machines/
```

| Path                             | Purpose                               | Why it exists                                                                    |
| -------------------------------- | ------------------------------------- | -------------------------------------------------------------------------------- |
| `machines/<host>/restic`         | Encrypted restic data store           | Primary deduplicated backup containing data and history.                         |
| `machines/<host>/exports/<date>` | Audit logs and inventory dumps        | Readable inspection without needing restic or password.                          |
| `media/`                         | Unmanaged external assets             | Separated from restic snapshots so backup runs do not traverse bulk media.       |
| `archive/<host>`                 | Retired machines                      | Retains old machine history without cluttering active host listings.             |
| `README.md`                      | Human documentation on the drive root | Explains how to inspect and restore files without requiring access to dots repo. |

### One-time drive layout migration

If an existing drive holds legacy folders from earlier ad-hoc backups, migrate them into the standardized layout:

```sh
B=/Volumes/backups; H=$(scutil --get LocalHostName)
mkdir -p "$B/machines/$H/exports/2026-11-04/legacy" "$B/media" "$B/archive"
mv "$B/20261104/"* "$B/machines/$H/exports/2026-11-04/legacy/" && rmdir "$B/20261104"
mv "$B/popcorn" "$B/media/"
```

---

## 5. The manifest

The backup policy is declared in `config/restic/backup.toml`:

```toml
#:schema ./backup.schema.json
# Backup policy for script/backup.ts (mise run backup, backup:restore, …).
# Every key, default and reason: docs/REINSTALL.md, "The manifest".

[repository]
root = "/Volumes/backups"                          # DOTS_BACKUP_ROOT overrides
path = "machines/{host}/restic"                    # {host}: scutil --get LocalHostName, or DOTS_BACKUP_HOST
password_command = "gopass show -o backups/restic" # skipped when a RESTIC_PASSWORD* variable is set

[backup]
paths = [
  # Personal files: no other copy
  "~/Documents",
  "~/Desktop",
  # … about 90 paths in 7 groups: XDG config, shell files, credentials, agents, tool settings, macOS settings
]
tags = ["{host}"] # backup.ts also adds home:<home>, which restore reads
exclude_caches = true # also skip any folder holding a CACHEDIR.TAG

[retention]
daily = 7
weekly = 4
monthly = 12
```

### Manifest keys

| Key                           | Type     | Default in file                   | Meaning                                                         | Why                                                                         |
| ----------------------------- | -------- | --------------------------------- | --------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `repository.root`             | string   | `"/Volumes/backups"`              | Backup drive mount root                                         | Allows environment override via `DOTS_BACKUP_ROOT`.                         |
| `repository.path`             | string   | `"machines/{host}/restic"`        | Path to restic repo relative to root                            | Keeps each machine isolated under its own folder.                           |
| `repository.password_command` | string   | `"gopass show -o backups/restic"` | Command that outputs repository password                        | Avoids hardcoding passwords in files.                                       |
| `backup.paths`                | string[] | 86 folders and files, in groups   | Folders and files to back up (an allowlist)                     | Only files with no other source; see [Why an allowlist](#why-an-allowlist). |
| `backup.tags`                 | string[] | `["{host}"]`                      | Tags applied to restic snapshots; `home:<home>` is always added | Identifies snapshots by machine; `restore` maps paths from the old home.    |
| `backup.exclude_caches`       | boolean  | `true`                            | Appends `--exclude-caches` to restic                            | Skips standard cache directories marked with `CACHEDIR.TAG`.                |
| `retention.daily`             | integer  | `7`                               | Number of daily snapshots to preserve                           | Daily rollback coverage for the past week.                                  |
| `retention.weekly`            | integer  | `4`                               | Number of weekly snapshots to preserve                          | Weekly rollback coverage for the past month.                                |
| `retention.monthly`           | integer  | `12`                              | Number of monthly snapshots to preserve                         | Monthly archive coverage for the past year.                                 |
| `exclude[].pattern`           | string   | —                                 | File or folder pattern to exclude                               | Excludes disposable or regenerated data.                                    |
| `exclude[].why`               | string   | —                                 | Mandatory rationale for exclusion                               | Documents why skipping this path is safe.                                   |

### Exclude patterns

Excludes apply only inside the allowed folders. Every exclusion is listed with its rationale:

| Pattern                               | Why                                                                                       |
| ------------------------------------- | ----------------------------------------------------------------------------------------- |
| `~/Work/dots-*`                       | dots worktrees (git worktree add ../dots-<topic>); their commits live in ~/Work/dots/.git |
| `**/.claude/worktrees`                | Claude Code worktrees; their commits live in the main repository                          |
| `~/.config/.fallow`                   | fallow cache                                                                              |
| `~/.claude/cache`                     | Claude Code cache                                                                         |
| `~/.claude/paste-cache`               | Claude Code paste cache                                                                   |
| `~/.claude/shell-snapshots`           | Claude Code shell snapshots; regenerated                                                  |
| `~/.claude/session-env`               | Claude Code session environment; regenerated                                              |
| `~/.claude/ide`                       | Claude Code IDE lock files                                                                |
| `~/.claude/file-history`              | Claude Code edit checkpoints (history)                                                    |
| `~/.claude/stats-cache.json`          | Claude Code stats cache                                                                   |
| `~/.claude/mcp-needs-auth-cache.json` | Claude Code MCP auth cache                                                                |
| `~/.omp/cache`                        | OMP cache                                                                                 |
| `~/.omp/puppeteer`                    | OMP headless browser download                                                             |
| `~/.omp/natives`                      | OMP native binaries                                                                       |
| `~/.omp/logs`                         | OMP logs                                                                                  |
| `~/.omp/run`                          | OMP runtime files                                                                         |
| `~/.omp/ssh-control`                  | OMP SSH control sockets                                                                   |
| `~/Work/mydemon/inspiration`          | Reference images (7 GiB); not worth keeping (owner, 2026-11-06)                           |
| `**/node_modules`                     | JavaScript dependencies; the package manager reinstalls them                              |
| `**/target`                           | Rust and Maven build output                                                               |
| `**/.gradle`                          | Gradle caches                                                                             |
| `**/.venv`                            | Python virtual environments; recreated from lock files                                    |
| `**/__pycache__`                      | Python bytecode                                                                           |
| `**/.DS_Store`                        | Finder metadata                                                                           |

*Note:* `~/Work/dots` is intentionally **not** excluded: its local branches and git stashes exist only on this machine.

### Path expansion and restic rules

- A leading `~` expands to `$HOME`.
- `{host}` expands to the machine host name (from `DOTS_BACKUP_HOST` or `scutil --get LocalHostName`).
- restic pattern semantics:
  - `**` matches directories recursively at any depth (e.g. `**/node_modules`).
  - Leading `/` anchors to the backup root.
  - restic does not perform shell tilde expansion, so `script/backup.ts` expands `~` before passing patterns to restic via a temporary `--exclude-file`.

### Adding a folder

Add it to `backup.paths` (keep the list short: only files with no other source), then run `mise run backup`.

### Adding an exclusion

To add an exclusion, append a new `[[exclude]]` block to `config/restic/backup.toml`:

```toml
[[exclude]]
pattern = "~/Work/some-project/build"
why = "Build output; recreated by the project's build"
```

Then validate the file:

```sh
taplo check config/restic/backup.toml
```

### Manifest validation

1. **Schema directive:** `#:schema ./backup.schema.json` at top of file provides editor autocompletion and hover validation.
2. **hk pre-commit:** `hk` runs `taplo-schema` to validate `config/restic/backup.toml` before any commit is accepted.
3. **Runtime check:** `script/backup.ts` runs `taplo check` on the manifest before executing any backup or restore command.
4. **Why TOML and JSON Schema:** Matches repository tooling conventions, integrates with taplo, and ensures every exclusion is accompanied by an audit reason.

---

## 6. Tasks

Global mise tasks are defined in `config/mise/conf.d/backup.toml`. Additional arguments must follow `--`.

### `mise run reinstall:audit`

Generates a read-only inspection report assessing what a reinstall would erase.

- **Flags:** `--stdout` (prints report to stdout instead of writing to disk).
- **Example:**
  ```sh
  mise run reinstall:audit
  mise run reinstall:audit -- --stdout
  ```
- **Output:** Writes report to `<root>/machines/<host>/exports/YYYY-MM-DD/MANIFEST.md` along with app lists and repository stats.

### `mise run backup:init`

Initializes an encrypted restic repository on the backup drive.

- **Flags:** None.
- **Example:**
  ```sh
  mise run backup:init
  ```
- **Behavior:** Idempotent; if `<repo>/config` already exists, outputs a notice and exits cleanly.

### `mise run backup`

Executes the backup per `config/restic/backup.toml` and runs `restic check`.

- **Flags:** None; paths, excludes and tags come from `config/restic/backup.toml` (`DOTS_BACKUP_MANIFEST` points at another manifest).
- **Example:**
  ```sh
  mise run backup
  ```
- **Behavior:** Writes expanded exclusions to a temp file, runs `restic backup`, warns if Full Disk Access is needed (exit 3), and performs repository integrity verification (`restic check`).

### `mise run backup:snapshots`

Lists existing snapshots for the current machine.

- **Example:**
  ```sh
  mise run backup:snapshots
  ```

### `mise run backup:restore`

Restores selected directories from a snapshot into the target directory.

- **Flags:**
  - `--include <path>`: Required relative path inside snapshot (e.g. `--include Work`).
  - `--snapshot <id>`: Snapshot ID (defaults to `latest`).
  - `--from-home <dir>`: Original user home folder (read from the snapshot's `home:` tag; older untagged snapshots of `~` use their only path).
  - `--target <dir>`: Target folder for restoration (defaults to `$HOME`).
  - `--dry-run`: Simulates restoration without modifying files.
- **Example:**
  ```sh
  mise run backup:restore -- --include Work --dry-run
  mise run backup:restore -- --include Work --include Documents
  ```

### `mise run backup:forget`

Applies retention rules (`--keep-daily`, `--keep-weekly`, `--keep-monthly`) and prunes unreferenced data blobs.

- **Example:**
  ```sh
  mise run backup:forget
  ```

### Exit codes

| Exit Code | Meaning                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------ |
| `0`       | Success.                                                                                         |
| `1`       | Setup error (missing backup root, uninitialized repository, invalid manifest schema).            |
| `2`       | Usage error (missing required `--include` on restore, unrecognized CLI command).                 |
| `3`       | Partial backup warning: some files could not be read due to macOS Full Disk Access restrictions. |
| *Other*   | Exit code forwarded directly from restic.                                                        |

*Safety guarantee:* No task creates or echoes passwords to terminal logs. `reinstall:audit` performs zero file modifications outside the dated export directory.

### Environment variables

| Variable                  | Description                                                                                  |
| ------------------------- | -------------------------------------------------------------------------------------------- |
| `DOTS_BACKUP_ROOT`        | Overrides backup storage root directory (defaults to `/Volumes/backups`).                    |
| `DOTS_BACKUP_HOST`        | Overrides host name identifier (defaults to `scutil --get LocalHostName`).                   |
| `DOTS_BACKUP_MANIFEST`    | Path to backup configuration TOML (defaults to `config/restic/backup.toml`).                 |
| `RESTIC_PASSWORD`         | Supplies restic repository password directly.                                                |
| `RESTIC_PASSWORD_FILE`    | Path to file containing restic password.                                                     |
| `RESTIC_PASSWORD_COMMAND` | Command to obtain password; empty string (`RESTIC_PASSWORD_COMMAND=`) prompts interactively. |

---

## 7. First-time setup

Perform this one-time setup on a new machine:

1. Install restic:
   ```sh
   brew install restic
   ```
2. Grant Full Disk Access to your terminal:
   - Open **System Settings → Privacy & Security → Full Disk Access**.
   - Enable your terminal application (e.g. Ghostty, iTerm2, Terminal).
3. Generate and record the restic password:
   ```sh
   gopass generate backups/restic 32
   ```
   *Critical:* Copy this password to your external password manager (1Password, Bitwarden).
4. Initialize the repository:
   ```sh
   mise run backup:init
   ```
5. Perform an initial backup:
   ```sh
   mise run backup
   ```
6. Verify restoration in a temporary directory:
   ```sh
   mise run backup:restore -- --include Documents --target "$(mktemp -d)"
   ```

### One secret: the age key

The age key that `install` asks for (`config/age/keys.txt`) decrypts the mise history. gopass's own identity
keyring (`~/.config/gopass/age/identities`) is locked to the same key, so a new machine needs that one secret
and gopass never asks for a PIN. Without this, the keyring has its own passphrase: macOS hides it (pinentry-mac
saved it in the Keychain), Linux asks for it on every `gopass show` and scripts fail with `pinentry error`.

Switch once, on a machine where gopass works (it asks for the old passphrase and to confirm the recipients).
The backup goes outside `config/gopass` (linked from `~/.config/gopass`):

```sh
bak="$HOME/.local/state/dots/gopass-identities.scrypt.bak"; mkdir -p "${bak%/*}"
cp -p ~/.config/gopass/age/identities "$bak"
gopass config age.keyring-identities '~/.config/age/keys.txt'
gopass config age.keyring-recipients "$(age-keygen -y ~/.config/age/keys.txt)"
gopass age identities reencrypt                               # old passphrase, then y
gopass show -o tokens/age.dots.github.com </dev/null          # prints with no prompt
head -n 2 ~/.config/gopass/age/identities                     # "-> X25519", no longer "-> scrypt"
cd ~/Work/dots && git add config/gopass && git commit -m "chore(gopass): Lock the keyring to the age key"   # SOPS encrypts age/
```

Delete the backup once a second machine decrypts. The old Keychain item (`GnuPG` / `pass/age-identities`) is no
longer used.

- **Recovery key:** keep the age key itself (the `AGE-SECRET-KEY-1…` line of `config/age/keys.txt`) as a
  Bitwarden secure note. It decrypts the history and the SOPS files in this repo (`config/gopass/age/` included),
  so it recovers gopass too: paste it when `install` asks. A second keyring recipient would not help on a new
  machine, where nothing opens without the age key.
- **Trade-off:** before the switch, the age key opened the history but not gopass: the keyring passphrase was a
  second factor. After it, the age key alone opens every gopass secret. Keep it `0600` on an encrypted disk
  (FileVault, LUKS) and only in Bitwarden off the machine.
- **Bootstrap check:** `mise bootstrap` warns while the keyring still uses a passphrase, or when the file named
  by `age.keyring-identities` is missing. It never changes gopass settings.

---

## 8. Reinstall playbook

### Phase 1: T-7 days (Preparation)

- [ ] Run the reinstall audit:
  ```sh
  mise run reinstall:audit
  ```
- [ ] Open `<root>/machines/<host>/exports/<date>/MANIFEST.md` and review flagged risks.
- [ ] Push uncommitted branches and add remotes for repositories without upstreams.
- [ ] Review `apps.txt` and add any desired missing applications to `config/homebrew/Brewfile`.
- [ ] Clean up local stashes and obsolete git worktrees.

### Phase 2: T-1 day (Pre-wipe backup)

- [ ] Verify age private key and restic password exist in your external password manager.
- [ ] Ensure 2FA recovery codes and license keys are in your password manager.
- [ ] Confirm browser sync is enabled or export bookmarks and profiles manually.
- [ ] Execute full backup and list snapshots:
  ```sh
  mise run backup
  mise run backup:snapshots
  ```
- [ ] Perform a test restore to verify data integrity:
  ```sh
  mise run backup:restore -- --include Documents --target "$(mktemp -d)"
  ```
- [ ] Run a final audit for the permanent record:
  ```sh
  mise run reinstall:audit
  ```
- [ ] Note the host name and user name recorded in `MANIFEST.md`.

### Phase 3: Wipe

- [ ] Unplug and safely eject the external backup drive.
- [ ] Sign out of Apple ID / iCloud (disables Activation Lock and Find My).
- [ ] Sign out of App Store and Music.
- [ ] Unpair Bluetooth devices to be reused.
- [ ] Erase the machine:
  - **System Settings → General → Transfer or Reset → Erase All Content and Settings**.

### Phase 4: Reinstall macOS and dots

- [ ] Complete macOS Setup Assistant:
  - Reuse the same short username if possible.
  - Enable **FileVault**.
- [ ] Install Xcode Command Line Tools:
  ```sh
  xcode-select --install
  ```
- [ ] Bootstrap dots using the one-liner:
  ```sh
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install)"
  ```
  Besides the age key and the GitHub login, `mise bootstrap` asks for two things, once each, on the terminal
  ([macOS guide](MACOS.md)):
  - **Your macOS password**, for `sudo`: it writes `/etc/pam.d/sudo_local` (Touch ID for `sudo`) before Homebrew,
    which then reuses that sudo session. Later `sudo` prompts take a fingerprint.
  - **The GitHub SSH key's passphrase**: stored in Keychain (`ssh-add --apple-use-keychain`), so git can sign
    commits; the `dev.mise.ssh-add` LaunchAgent loads it at every login.

  Run unattended (no terminal), both are skipped with a message; rerun
  `mise bootstrap --only files,macos-defaults,macos-launchd-agents,task` from a terminal to finish them.
- [ ] Trust any third-party taps flagged by the audit:
  ```sh
  brew trust can1357/tap
  brew bundle install --file ~/.config/homebrew/Brewfile
  ```

### Phase 5: Restore data

Connect the backup drive and restore data directories:

```sh
# Dry run first to verify mapping
DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work --include Documents --dry-run

# Real restoration
DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work --include Documents
```

> **Warning:** Never restore `.config`, `.ssh`, `.gnupg`, `.local`, or `Library` wholesale. `install` sets these up as symlinks into the dots repository; overwriting them destroys the links.

### Phase 6: Post-restore verification

- [ ] Validate Homebrew packages:
  ```sh
  brew bundle check --file ~/.config/homebrew/Brewfile
  ```
- [ ] Check bootstrap tool status:
  ```sh
  mise bootstrap status --missing
  ```
- [ ] Verify secrets and credentials:
  ```sh
  gopass ls
  gh auth status
  mise dot status
  ```
- [ ] Inspect git repositories in `~/Work` (`git status`).
- [ ] Initialize backup repository for new machine name (if changed):
  ```sh
  mise run backup:init
  mise run backup
  ```

### Phase 7: T+1 week (Cleanup)

- [ ] Turn on Time Machine if desired.
- [ ] Run retention cleanup:
  ```sh
  mise run backup:forget
  ```
- [ ] Move old machine backups to archive:
  ```sh
  mv /Volumes/backups/machines/<old host> /Volumes/backups/archive/
  ```


---

## Bootstrap runbook

A condensed checklist for provisioning a clean machine from scratch:

1. **Before wiping the old Mac:**
   - Push secrets history: `mise dot sync`
   - Run the reinstall audit: `mise run reinstall:audit`
   - Run a full restic backup: `mise run backup`
   - Confirm age root secret (`config/age/keys.txt`, recipient `config/age/recipient.txt`) is in your password manager
2. **On the new Mac:**
   - Complete macOS Setup Assistant; sign in to Apple Account and App Store
   - Install command-line tools: `xcode-select --install`
   - Run the bootstrap script:
     ```sh
     curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash
     ```
   - Paste the age key when prompted; `install` adopts `dots-history` and runs `mise bootstrap -E desktop`
   - For the development tools (IDEs, language servers, Docker, coding agents, agent skills): `mise run setup dev`.
     Agent skills are then restored in the background (log: `~/.local/state/dots/skills-restore.log`)
3. **Restore data and verify:**
   - Mount backup drive and restore data directories:
     ```sh
     DOTS_BACKUP_HOST=<old-host> mise run backup:restore -- --include Work
     ```
   - Open a new shell: `mise bootstrap status` reports no pending changes
---

## 9. Recovery without gopass

If gopass is not yet restored or operational on the new system, pass an empty `RESTIC_PASSWORD_COMMAND` to prompt interactively:

```sh
RESTIC_PASSWORD_COMMAND= DOTS_BACKUP_HOST=<old host> mise run backup:restore -- --include Work
```

To restore on a system without dots installed, use native restic commands directly:

```sh
restic --repo /Volumes/backups/machines/<host>/restic restore latest:/Users/<old user> --target ~ --include /Work
```

---

## 10. Heads-ups and considerations

1. **Drive filesystem:** The backup drive is unencrypted HFS+. restic repositories are encrypted at rest with AES-256. Files placed in `exports/legacy/` are unencrypted; never copy raw tokens or private keys there.
2. **Full Disk Access:** Without Full Disk Access, macOS blocks terminal access to Safari, Mail, and Messages data, causing restic exit code 3.
3. **Host name changes:** If the new macOS installation assigns a different computer name, specify `DOTS_BACKUP_HOST=<old host>` to restore from the old repository.
4. **Allowlist only:** Only `backup.paths` is read, so cloud drives (Google Drive, Dropbox, iCloud) and new folders elsewhere in `~` are never backed up; move a file you need into an allowed folder.
5. **Repositories without remotes:** The audit flags repositories with zero git remotes; ensure critical repositories have upstreams.
6. **Large folders:** Large non-git folders (e.g. local build trees, model weights) significantly increase backup time; exclude them if recreatable.
7. **Keychain and application state:** macOS Keychain entries, browser session caches, and Mail databases are not managed by dots.
8. **restic lock contention:** If a backup is interrupted, restic retains a lock file. Unlock the repository using `restic --repo <path> unlock`.
9. **Disk space exhaustion:** If the backup drive nears capacity, execute `mise run backup:forget` to prune aged snapshots.

---

## 11. Best practices

- **Regular test restores:** Verify restoration into a temporary folder every few months to guarantee restic snapshots remain readable and valid.
- **3-2-1 strategy:** An external USB drive constitutes one copy. Replicate your restic repository off-site using `restic copy` or cloud backends (e.g. Backblaze B2, S3).
- **Audit before wipe:** Always run `mise run reinstall:audit` prior to wiping an operating system.
- **Justified exclusions:** Require every exclude pattern in `config/restic/backup.toml` to provide a clear `why` field.
- **Controlled retention:** Balance retention periods against available disk capacity.

---

## 12. Troubleshooting

| Symptom                                                      | Cause                                             | Solution                                                                                                        |
| ------------------------------------------------------------ | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `backup root not found: <dir>`                               | External drive not mounted or wrong mount point.  | Connect the drive or set `DOTS_BACKUP_ROOT=/path/to/drive`.                                                     |
| `no repository at <path>`                                    | Repository not initialized or wrong host name.    | Run `mise run backup:init` or set `DOTS_BACKUP_HOST=<old host>`.                                                |
| `password command failed`                                    | gopass password entry missing or gopass locked.   | Generate password via `gopass generate backups/restic 32` or unlock gopass.                                     |
| `Enter your PIN` from gopass, or `pinentry error` in scripts | The gopass keyring still uses its own passphrase. | Lock it to the age key: [One secret: the age key](#one-secret-the-age-key).                                     |
| `wrong password or no key found`                             | Supplied restic password does not match repo key. | Verify password in password manager; test with `restic --repo <path> key list`.                                 |
| `repository is already locked`                               | Prior restic process was aborted abruptly.        | Remove stale locks with `restic --repo <path> unlock`.                                                          |
| Backup exits with code `3`                                   | Protected macOS directories unreadable.           | Grant Full Disk Access to Terminal/Ghostty in macOS System Settings.                                            |
| `manifest fails its schema`                                  | Syntax error or missing `why` in `backup.toml`.   | Run `taplo check config/restic/backup.toml` and correct reported validation errors.                             |
| Restore completed but files missing                          | Mismatched `--from-home` path or exclude filter.  | Run with `--dry-run --verbose` to inspect path mappings and ensure `--include` matches snapshot relative paths. |

---

## 13. See also

- Dots repository overview: [`README.md`](../README.md)
- Backup configuration manifest: [`config/restic/backup.toml`](../config/restic/backup.toml)
- Backup CLI implementation: [`script/backup.ts`](../script/backup.ts)
- Official restic documentation: [https://restic.readthedocs.io](https://restic.readthedocs.io)

## 14. Quick reference

### mise tasks

The tasks wrap `script/backup.ts`: they read the drive, repository and password from `config/restic/backup.toml`, so
no restic variables are needed. Only `backup:restore` and `reinstall:audit` take flags (after `--`).

```sh
# Setup (once per machine)
mise run backup:init                                # create this machine's restic repository on the drive (idempotent)

# Routine
mise run backup                                     # back up backup.paths (minus excludes), then restic check; only changes are stored
mise run backup:snapshots                           # list this machine's snapshots: ID, date, host, paths
mise run backup:forget                              # apply retention (7 daily, 4 weekly, 12 monthly) and prune unused data

# Before a wipe
mise run reinstall:audit                            # what a reinstall would lose: MANIFEST.md in exports/<date>/ on the drive
mise run reinstall:audit -- --stdout                # same report, printed instead of written

# Restore (paths are relative to the old home; repeat --include for several)
mise run backup:restore -- --include Documents --dry-run                      # what would be restored, and where
mise run backup:restore -- --include Documents --target /tmp/check            # restore into a scratch folder to inspect
mise run backup:restore -- --include Work --include .config/ssh               # restore into ~ (overwrites same-name files)
mise run backup:restore -- --snapshot 61d6acf7 --include .aws                 # from a given snapshot (default: latest)
mise run backup:restore -- --from-home /Users/old --include Work              # snapshot without a home: tag (older runs)

# Overrides (environment)
DOTS_BACKUP_HOST=<old host> mise run backup:snapshots     # another machine's repository (e.g. after a host rename)
DOTS_BACKUP_ROOT=/Volumes/other mise run backup            # another drive
DOTS_BACKUP_MANIFEST=/tmp/backup.toml mise run backup      # a one-off manifest (wider or narrower paths)
```

### restic commands

restic itself needs the repository and password. Set them once per terminal:

```sh
export RESTIC_REPOSITORY="/Volumes/backups/machines/$(scutil --get LocalHostName)/restic"
export RESTIC_PASSWORD_COMMAND="gopass show -o backups/restic"   # without gopass: export RESTIC_PASSWORD='…' (password manager)
```

Snapshots are named by ID (`61d6acf7`) or `latest`. Paths inside a snapshot are absolute (`/Users/<user>/…`); `~`
works when the user is the same.

```sh
# Inspect
restic snapshots                                    # every snapshot: ID, date, host, tags, paths
restic snapshots --tag pre-reinstall                # only snapshots with a tag
restic ls latest | less                             # every file in the newest snapshot
restic ls latest ~/.config/ssh                      # only one folder
restic ls --long latest ~/Documents                 # with permissions, size and date
restic stats latest                                 # file count and total size of one snapshot
restic stats --mode raw-data                        # space the repository really uses on the drive (deduplicated, compressed)

# Search and compare
restic find '*.toml' 'keybindings.json'             # which snapshots hold matching files (glob patterns)
restic find --snapshot latest '*.pem'               # search one snapshot only
restic diff de6ddca2 latest                         # what changed between two snapshots (+ added, - removed, M modified)
restic dump latest ~/.zshrc                         # print one file without restoring it
restic dump latest ~/.config/ssh > ssh.tar          # a folder comes out as a tar archive

# Restore (prefer mise run backup:restore, which maps the old home to the new one)
restic restore latest --target /tmp/r --include ~/Documents       # recreates /tmp/r/Users/<user>/Documents
restic restore latest --target /tmp/r --include ~/Work --dry-run -v   # list what would be restored

# Maintenance
restic check                                        # repository structure and index (mise run backup runs it)
restic check --read-data-subset=5%                  # also read and verify 5% of the stored data (slow; rotate now and then)
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 12 --dry-run   # what backup:forget would remove
restic forget 5629dad1                              # drop one snapshot (data stays until prune)
restic prune                                        # free the space of data no snapshot uses
restic unlock                                       # clear a stale lock after an interrupted run
restic cache --cleanup                              # remove old local caches (~/Library/Caches/restic)

# Password
restic key list                                     # keys that open the repository
restic key passwd                                   # change the password (then update gopass backups/restic and the password manager)
```
