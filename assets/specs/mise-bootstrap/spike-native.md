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
