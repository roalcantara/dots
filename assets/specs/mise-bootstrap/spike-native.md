<!-- markdownlint-disable -->
# Spike: can mise replace `install` and the secrets archive?

**Status:** to run. **Time box:** half a day. **Owner decision depends on it:** keep the rewritten `install` +
`script/prepare-secrets` + `assets/dump.zip.enc`, or replace them with mise's native flow.

## Why

mise already does most of what `install` does (see the comparison in the 2026-10-29 review). Two things are
unproven: whether mise's **encrypted dotfile history** can carry `~/.ssh` and `~/.gnupg` (binary files, modes)
to a fresh machine, and whether `mise bootstrap --from`/`--adopt` can replace `install`'s clone-and-link step.

References: https://mise.jdx.dev/dotfiles.html, https://mise.jdx.dev/dotfiles/encryption.html,
https://mise.jdx.dev/dotfiles/history.html, https://mise.jdx.dev/bootstrap/setup.html,
https://mise.jdx.dev/bootstrap.html.

## Prompt for the agent

```text
Run a time-boxed spike in ~/Work/dots (branch feat/mise-bootstrap). Everything runs in Docker; nothing on the
host Mac. Read assets/specs/mise-bootstrap/spike-native.md (this file) and answer its questions with evidence.

Rules: never run mise bootstrap, mise dot, or install (without --dry-run) on the host; never use real secrets
(generate throwaway keys inside containers); never touch assets/dump.zip.enc; create no GitHub repositories and
push nothing — the "origin" is a bare git repo on a Docker volume; don't write to /Volumes/meex900. Pin mise to
the version on the host (`mise --version`). Commit only the spike files and the report (signed Conventional
Commits, `git add <paths>`).
```

## Setup

Put reproducible files under `assets/specs/mise-bootstrap/spike/` (a `Dockerfile` based on
`mcr.microsoft.com/devcontainers/base:debian`, and one `run.sh` per experiment). Use a named volume `spike-origin`
holding a bare repo (`git init --bare /origin/history.git`) shared by containers A and B. Run as the base
image's `vscode` user (it has passwordless sudo), installing mise with
`curl -fsSL https://mise.run | MISE_VERSION=v<pin> sh`.

## Experiments and questions

| # | Experiment | Question | Pass when |
| --- | --- | --- | --- |
| 1 | Container A: generate a machine age identity (`~/.config/mise/age.txt`, 600) and a recovery identity (kept outside the container's home, e.g. on the volume under `/origin/recovery.txt`); write a global `~/.config/mise/config.toml` with `[history.encryption] recipients = [machine, recovery]` and `[dotfiles]` entries `"~/.ssh" = { mode = "track", encrypt = true }` and `"~/.gnupg" = { mode = "track", encrypt = true }`; create a throwaway ssh key (`ssh-keygen -t ed25519 -N ''`) and a throwaway GPG key (`gpg --batch --quick-gen-key` with no passphrase, so `pubring.kbx`, `trustdb.gpg`, `private-keys-v1.d/*` exist); set `~/.ssh` 700 / files 600; save and sync to the origin (`mise dot origin set …`, `mise dot save`, `mise dot sync`) | Can whole folders, including binary files, be tracked encrypted? Does a file-path origin work? | Sync succeeds; record the exact commands that worked |
| 2 | Inspect `/origin/history.git` (clone it bare-read-only, `git log -p`) | Is anything readable in plaintext? | No private-key header or key material in any blob; record what is visible (file names, sizes) |
| 3 | Fresh container B (new home): install mise, copy only `/origin/recovery.txt` to `~/.config/mise/age.txt` (600), run `mise bootstrap --adopt <origin>` (or the documented equivalent) | Does a fresh machine with only the recovery identity get everything back? | `sha256sum` of every restored file matches A; modes are 700/600; `ssh-keygen -y -f ~/.ssh/id_ed25519` and `gpg --list-secret-keys` work; record any manual step needed |
| 4 | In B, run the same adopt/bootstrap again; then change a file in A, sync, pull in B | Idempotent and updatable? | Second run changes nothing; the change arrives |
| 5 | In a fresh container C, without `install`: `mise bootstrap --from <a local clone or bundle of this dots repo> --from-dir ~/Work/dots --config-dir config/mise -E container --skip user --yes` (use `git bundle` or a file URL of the committed tree, not the host working tree) | Can mise alone clone `dots`, link `~/.config/mise`, and apply `conf.d` (packages, links, directories, task)? | Bootstrap completes; `~/.config/mise` links into the checkout; the CST in `distros/debian/container-structure-test.yml` passes against a committed image of C (or record which checks fail and why) |
| 6 | In C, combine both models: add the encrypted-history config of experiment 1 to C and adopt it alongside the `dots` links | Do `track` (encrypted, in place) and `symlink` entries coexist without conflicts? | Both apply; `mise dot status` clean |
| 7 | In C, declare `[bootstrap.files."/etc/sudoers.d/spike"]` (owner root, mode 0440, content `vscode ALL=(ALL) NOPASSWD:ALL`) and a `[bootstrap.hooks] post-packages = "…"` hook writing a marker file | Does mise handle root-owned system files via sudo and run hooks as documented? | File exists with root:root 0440 and passes `visudo -cf`; the hook ran (record the exact hook key syntax that worked) |

## Deliverable

Append to this file a **Results** section: one row per experiment (pass/fail, evidence, the exact working
commands and config), a list of gaps and workarounds, and a **Recommendation**:

- **Native:** replace `install` with a few lines (install mise, `mise bootstrap --from …` or `--adopt …`) and
  drop `script/prepare-secrets` and `assets/dump.zip.enc`, moving secrets to an encrypted history synced to a
  private origin, with the recovery identity in the password manager; or
- **Hybrid:** native for everything except what failed (name it), with the archive kept only for that; or
- **Keep:** the current `install` if mise cannot do experiments 3 and 5.

Then list the plan changes (tasks to drop, add or rewrite in `tasks.md`) the recommendation implies, without
applying them. Stop there.

## Results

Spike executed in Docker on 2026-10-29. Pinned mise version: `v2026.10.22` (matching host).
Reproducible test harness committed under `assets/specs/mise-bootstrap/spike/` (`Dockerfile`, `run.sh`, `exp1/`–`exp7/`).

| # | Experiment | Status | Evidence | Working commands & config |
|---|------------|--------|----------|---------------------------|
| 1 | Container A: age identities, encrypted tracking of `~/.ssh` and `~/.gnupg`, save & sync to bare origin | **PASS** | `mise dot save` captured 8 files (omitting runtime agent sockets `~/.gnupg/S.gpg-agent*`). Checkpoint published to `main` ref of bare origin. Git objects show `mise-encrypted-file-v1` format. | `age-keygen -o ~/.config/mise/age.txt`<br>`age-keygen -o /origin/recovery.txt`<br>`mise dot origin set /origin/history.git --sync manual -y`<br>`mise dot save && mise dot sync`<br>Config:<br>`[history.encryption] recipients = ["<machine>", "<recovery>"]`<br>`[dotfiles]`<br>`"~/.ssh" = { mode = "track", encrypt = true }`<br>`"~/.gnupg" = { mode = "track", encrypt = true }` |
| 2 | Bare origin inspection (`git log -p`) | **PASS** | `git log -p main` confirms zero plaintext leaks. Zero occurrences of `BEGIN OPENSSH PRIVATE KEY` or GPG private key material in any blob. File names, modes (`448` = 0700, `384` = 0600), age public keys, and blob sizes are visible in `.mise-history/manifest.json`. | `git log --stat main`<br>`git show main:.mise-history/manifest.json`<br>`git show main:home/.ssh/id_ed25519` |
| 3 | Fresh Container B recovery with recovery identity only | **PASS** | Restored all 12 files/directories. `diff -u` on SHA256 checksums vs Container A is identical. Permissions match exactly (700 for directories, 600 for keys). `ssh-keygen -y -f ~/.ssh/id_ed25519` prints public key. `gpg --list-secret-keys` recognizes secret key. | Pre-requisite: `cp /origin/recovery.txt ~/.config/mise/age.txt && chmod 600 ~/.config/mise/age.txt`<br>Restore: `mise bootstrap --adopt /origin/history.git --yes`<br>Verification:<br>`ssh-keygen -y -f ~/.ssh/id_ed25519`<br>`gpg --list-secret-keys` |
| 4 | Idempotency and update propagation (A -> origin -> B) | **PASS** | Second adopt run in B reported `Wrote 0 file(s)` and changed nothing. New file `~/.ssh/config` created in A, saved, and synced to origin. In B, `mise dot sync` fetched 1 pending change; `mise dot pull --yes` applied `~/.ssh/config` with mode 600. | Second adopt: `mise bootstrap --adopt /origin/history.git --yes`<br>In A: `mise dot save && mise dot sync`<br>In B: `mise dot sync && mise dot pull --yes` |
| 5 | Container C: `mise bootstrap --from` directly without `install` | **PARTIAL PASS / GAPS** | Cloned to `~/Work/dots` and linked `~/.config/mise -> ~/Work/dots/config/mise`. Installed 45 Homebrew bottles, 7 font casks, and apt `fontconfig` via sudo. Failed initially on `dotfiles` because `dotfiles.toml` hardcodes sources at `~/.local/share/dots/config/...`. With `ln -s ~/Work/dots ~/.local/share/dots` and `--force-dotfiles`, dotfiles completed. In `tools` phase, `pipx:yamllint` failed because Python 3.15 lacks prebuilt `pyyaml==6.0.3` wheels on linux-arm64 (`--no-build`). Skipping tools allowed `tasks.bootstrap` to run. CST command tests (all 7) passed against the image. | Initial failure command:<br>`mise bootstrap --from /origin/dots.bundle --from-dir ~/Work/dots --config-dir config/mise -E container --skip user --yes`<br>Working command with workarounds:<br>`ln -s ~/Work/dots ~/.local/share/dots`<br>`mise bootstrap --from /origin/dots.bundle --from-dir ~/Work/dots --config-dir config/mise -E container --skip user,tools --yes --force-dotfiles` |
| 6 | Coexistence of `track` (encrypted secrets) and `symlink` (repo dotfiles) | **PASS** | Confirmed TOML prohibits duplicate table keys for the same path (e.g. `~/.ssh` cannot be declared as both `symlink` in `dotfiles.toml` and `track` in `config.toml`). When `~/.ssh` and `~/.gnupg` are removed from `dotfiles.toml` and tracked via encrypted history, symlinks and tracked entries coexist without conflict. `mise dot status` reports clean: `✓ 2 entries up to date`. | `mise bootstrap --adopt /origin/history.git --yes`<br>`mise dot apply --force`<br>`mise dot status` |
| 7 | Root-owned system files via sudo and bootstrap hooks | **PASS** | Mise automatically invoked `sudo /home/vscode/.local/bin/mise ... bootstrap __apply-system-plan`. Created `/etc/sudoers.d/spike` owned by `root:root` with mode `0440` (`-r--r-----`), which passed `sudo visudo -cf`. Hook `post-packages` executed right after the packages phase and wrote `/tmp/hook-marker-spike.txt`. | Config:<br>`[bootstrap.files."/etc/sudoers.d/spike"]`<br>`content = "vscode ALL=(ALL) NOPASSWD:ALL\n"`<br>`mode = "0440"`<br>`owner = "root"`<br>`group = "root"`<br>`[bootstrap.hooks]`<br>`post-packages = "touch /tmp/hook-marker-spike.txt"`<br>Execution: `mise bootstrap --only files,packages --yes -v` |

### Gaps and Workarounds

1. **Source path divergence in `dotfiles.toml`:**
   - *Gap:* `dotfiles.toml` hardcodes sources to `source = "~/.local/share/dots/config/..."`. Running `mise bootstrap --from ... --from-dir ~/Work/dots` clones the repo into `~/Work/dots`. Every dotfile link fails with `mise ERROR files: sources do not exist`.
   - *Workaround:* Either pass `--from-dir ~/.local/share/dots`, create a symlink `~/.local/share/dots -> ~/Work/dots`, or update `dotfiles.toml` to reference `~/Work/dots` (or relative path if mise supports relative sources from config dir).
2. **Pre-existing dotfiles conflict in container/host environments:**
   - *Gap:* Base images (like Debian devcontainers) and fresh hosts already have default files `~/.bashrc` and `~/.profile`. Mise halts whole-file symlink creation with `mise ERROR files: refusing to overwrite existing files`.
   - *Workaround:* `--force-dotfiles` must be passed to `mise bootstrap`.
3. **Missing system packages (`flatpak`):**
   - *Gap:* In minimal container environments, `flatpak` is absent, so `flatpak-user` packages are skipped with a warning.
   - *Workaround:* Normal container profile behavior; container environments should keep flatpaks skipped or unset.
4. **Tool wheel build failures under Python 3.15:**
   - *Gap:* Brew on Linux arm64 installs Python 3.15.2. `pipx:yamllint` fails because `pyyaml==6.0.3` has no binary wheel on PyPI for CPython 3.15 on linux-arm64, and mise's backend passes `--no-build`.
   - *Workaround:* Pin Python tool version to 3.12 or 3.13, or pass `--skip tools` during initial base bootstrapping until build prerequisites exist.
5. **Initial host provisioning:**
   - *Gap:* On a bare Linux host, mise cannot perform user creation (`useradd`), password setup, or initial sudoers configuration without an already existing user context and passwordless sudo.
   - *Workaround:* A minimal host entrypoint (15–20 lines) or devcontainer lifecycle hook is still required to create the user and install mise before `mise bootstrap` runs.

## Recommendation

**Hybrid (Native Encrypted History for Secrets + Declarative `mise bootstrap` driven by a lean entrypoint)**

### Why
1. **Secrets:** Mise's native encrypted history completely passed (Experiments 1–4). It successfully encrypts and decrypts whole directories (`~/.ssh`, `~/.gnupg`), preserves strict permissions (0700/0600), completely avoids plaintext leaks in git history, and allows full disaster recovery with a single recovery key from a password manager. **We should drop `script/prepare-secrets` and `assets/dump.zip.enc`.**
2. **Dotfiles & Packages:** `mise bootstrap` handles packages, casks, directories, root system files via sudo, hooks, and dotfile symlinks natively (Experiments 5–7).
3. **The Entrypoint:** `install` does not need 842 lines of legacy shell. However, a minimal, focused `install` entrypoint (or one-liner) is still necessary to:
   - Create user/sudo privileges if running on a fresh host VM;
   - Pass `--force-dotfiles` to avoid collisions with default shell files;
   - Place the recovery age key into `~/.config/mise/age.txt` (or prompt for it) before running `mise bootstrap --adopt <secrets-repo>`.

### Plan changes implied (for `tasks.md`, not applied)

1. **Tasks to drop:**
   - Drop tasks related to `script/prepare-secrets` maintenance and fixture archive creation (`--fixture`, `fixture.zip.enc`).
   - Drop tasks managing `assets/dump.zip.enc` SOPS encryption and decryption pipelines.
2. **Tasks to add:**
   - **Task (Secrets migration to mise encrypted history):** Enroll `~/.ssh` and `~/.gnupg` into mise's encrypted history (`mode = "track", encrypt = true`) with age recipients (workstation identity + 1Password recovery key). Push history to private bare repository or private GitHub repo.
   - **Task (Clean `dotfiles.toml`):** Remove the obsolete symlink entries for `"~/.ssh"` and `"~/.gnupg"` pointing to `"~/.config/ssh"` and `"~/.config/gnupg"`.
   - **Task (Fix `dotfiles.toml` checkout path):** Align `source` paths in `dotfiles.toml` between `~/.local/share/dots` and `~/Work/dots` (or ensure `~/.local/share/dots` symlink is created during bootstrap directories).
   - **Task (Python tool compatibility on Linux arm64):** Pin Python for `pipx` tools in `config/mise/config.toml` to a version with pre-compiled wheels (e.g. 3.12/3.13) so `yamllint` installs cleanly without local C compilation.
3. **Tasks to rewrite:**
   - **Task 7 (Debian image build & rehearsal):** Update rehearsal instructions to use `mise bootstrap --adopt <secrets-origin>` with a throwaway age recovery key instead of `install --secrets <fixture.zip.enc>`.
   - **Task 8 (Ubuntu VM rehearsal):** Rewrite VM curl one-liner to fetch the recovery key, install pinned mise, and run `mise bootstrap --adopt <origin>` and `mise bootstrap --from <repo> --force-dotfiles`.
