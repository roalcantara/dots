# ~/.config audit — design

Status: approach approved by the owner (2026-11-04): a one-off review, **no guard** (no unmanaged list, no audit
section). Port rule: **installed and customized**.

Revised (owner, 2026-11-04): **one way of handling things**. Every kept entry is a link from `~/.config/<app>` to
`config/<app>`; files that hold secrets are committed **SOPS-encrypted**, by a rule covering the app's whole
folder (as `config/ssh/keys/*.key` and `config/.env` already are). gopass moves out of the encrypted history into
`config/gopass`. Unchanged this round: `ssh`, `gnupg` (permissions; a separate change).

Owner review (2026-11-04): every proposed verdict accepted, except **`vicinae` and `goose`: Remove**. No history
exception remains, so the Track verdict is gone.

## 1. Goal

Every entry in `~/.config` that is not in `config/` ends in exactly one place:

| Verdict           | Meaning                                            | Where it lands                                                                                                                                 |
| ----------------- | -------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| **Port**          | App installed, settings customized, no secrets     | `config/<app>/`, linked by `config/mise/conf.d/dotfiles.toml`                                                                                  |
| **Port (secret)** | As Port, but some files hold a credential          | `config/<app>/`, linked; secret files committed SOPS-encrypted (`.gitattributes` `filter=sops diff=sops` + a `.sops.yaml` rule for the folder) |
| **Leave**         | Cache or state the app writes and recreates        | Untouched                                                                                                                                      |
| **Remove**        | Broken link, empty folder, app not installed, or owner's choice | Deleted; non-empty folders are first moved to `~/.local/state/dots/config-aside-<date>/`                                                       |

Already correct, out of scope: `kb` (link to `config/kodexb`). Unchanged this round: `ssh`, `gnupg` (tracked,
encrypted; `config/ssh` also exists in the repo, so ssh is handled twice: a follow-up).

## 2. Evidence method (2026-11-04, this Mac)

- Installed: per-app lookup (formula, cask, `/Applications/<App>.app`, `command -v`); a mise shim counts.
- Files, size, last change: `find`, `du -sh`, `stat`.
- Secrets: file names and key-name patterns (`token|secret|password|api_key|oauth|private_key`) only; no value is
  printed or copied.
- Customized: hand-written content beyond the app's generated default (comments, keymaps, settings changed).

Verified for the revised approach (2026-11-04, throwaway `HOME`, gopass 1.17.4, test key only):

| Check                                                                            | Result                                                                                                    |
| -------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| gopass with `~/.config/gopass` a link to a repo-like `config/gopass`             | read ✓; insert and `gopass config` write through it ✓; stays a link ✓                                     |
| `sops encrypt --input-type binary` of the X25519 `identities` file, then decrypt | JSON envelope; decrypted file identical byte for byte ✓                                                   |
| `script/clean.sops.sh` / `smudge.sops.sh`                                        | infer the type from `--filename-override`: no extension → binary (as `*.key` today), `.yml` → YAML values |

Gap found: `install` clones the repo **before** the age key and `setup:git:filters` exist, and `setup:git:filters`
only sets git config, so SOPS files stay encrypted in the working tree of a new machine (§4 step 0).

## 3. Inventory and proposed verdicts

Owner: mark **OK** or write the verdict you want in the last column. Nothing changes on disk before this table is
approved.

### 3.1 Remove: broken links (9)

Targets deleted from the repo earlier (closeout #95, packages #92, or never committed).

| Entry         | Target                                                                               | Owner |
| ------------- | ------------------------------------------------------------------------------------ | :---: |
| `amethyst`    | `config/amethyst` (closeout)                                                         |  OK   |
| `bunfig.toml` | `~/Work/dots/config/bunfig.toml` (absolute link; never in git)                       |  OK   |
| `cursor`      | `config/cursor` (closeout)                                                           |  OK   |
| `glide`       | `config/glide` (closeout)                                                            |  OK   |
| `ranma`       | `config/ranma` (closeout)                                                            |  OK   |
| `rift`        | `config/rift` (closeout)                                                             |  OK   |
| `skhd`        | `config/skhd` (closeout)                                                             |  OK   |
| `starship`    | `config/starship` (#92)                                                              |  OK   |
| `tealdeer`    | `config/tealdeer` (never in git; `brew "tealdeer"` stays, it works without a config) |  OK   |

### 3.2 Remove: empty folders (8)

`act`, `crewai`, `crush`, `devin`, `firebase`, `obsidian`, `rclone`, `swiftpm`: 0 bytes each. (At removal,
`crush`, `devin` held empty `skills/` link folders and `swiftpm` links into `~/Library`: moved aside, not deleted.
A skills restore may recreate `crush`/`devin`.)

Owner (all 8): OK

### 3.3 Remove: app not installed (moved aside first)

| Entry              | Files       | Notes                                                                                                 | Owner |
| ------------------ | ----------- | ----------------------------------------------------------------------------------------------------- | :---: |
| `.agents`          | 1 skill dir | `yabai-skhd-doctor` skill; yabai/skhd removed                                                         |  OK   |
| `skills-lock.json` | 1           | Lock for that one skill only                                                                          |  OK   |
| `.DS_Store`        | 1           | Finder metadata                                                                                       |  OK   |
| `.rz`              | 994         | `rz` not installed; plugin repo clones (cache) plus `config.toml`                                     |  OK   |
| `.semgrep`         | 1           | `semgrep` not installed                                                                               |  OK   |
| `acli`             | 8           | Atlassian CLI not installed                                                                           |  OK   |
| `aegis`            | 4           | yabai helper scripts; yabai removed                                                                   |  OK   |
| `amp`              | 1           | Amp plugin; `amp` not installed                                                                       |  OK   |
| `AWSVPNClient`     | 5           | AWS VPN Client not installed; connection profiles inside                                              |  OK   |
| `cagent`           | 2           | first-run marker, user uuid                                                                           |  OK   |
| `configstore`      | 2           | firebase-tools state (**credential**); firebase not installed                                         |  OK   |
| `crossnote`        | 4           | crossnote not installed                                                                               |  OK   |
| `gcloud`           | 2120        | **credentials** (`application_default_credentials.json`, `legacy_credentials/`); gcloud not installed |  OK   |
| `ghostex`          | 3           | Ghostex not installed                                                                                 |  OK   |
| `gitlint`          | 1           | gitlint not installed                                                                                 |  OK   |
| `graphite`         | 3           | **credential** (`auth`); `gt` not installed                                                           |  OK   |
| `karabiner`        | 2           | Karabiner-Elements not installed                                                                      |  OK   |
| `KiwiDesk`         | 5           | KiwiDesk not installed                                                                                |  OK   |
| `macterm`          | 1           | MacTerm not installed                                                                                 |  OK   |
| `marp`             | 39          | marp-cli not installed (7.1M)                                                                         |  OK   |
| `nx`               | 1           | `nx` not installed                                                                                    |  OK   |
| `openspec`         | 1           | `openspec` not installed                                                                              |  OK   |
| `presenterm`       | 1           | presenterm not installed                                                                              |  OK   |
| `puppeter`         | 1           | Misspelled folder: Puppeteer never reads it                                                           |  OK   |
| `reveal-md`        | 1           | reveal-md not installed                                                                               |  OK   |
| `sketchybar`       | 6           | sketchybar not installed                                                                              |  OK   |

### 3.4 Port (installed, customized, no secrets)

| Entry     | Port                                                                      | Exclude (stays local)                                                   | Owner  |
| --------- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------- | :----: |
| `zed`     | `settings.json` (187 lines), `keymap.json` (217), `themes/` (empty: skip) | `conversations/`, `prompts/` (database), `keymap_backup.json`           |   OK   |
| `zentty`  | `config.toml` (102 lines), `bookmarks.json`                               | `restore-*.json`, `run/`                                                |   OK   |
| `dprint`  | `dprint.jsonc` (63 lines, global config)                                  | —                                                                       |   OK   |
| `posting` | `config.yaml` (38 lines)                                                  | —                                                                       |   OK   |
| `gh`      | `config.yml` (aliases, settings)                                          | `hosts.yml` (token: SOPS, §3.5)                                         |   OK   |

Every ported app uses a **folder link** (`"~/.config/<app>" = { source = …/config/<app> }`). Local state stays in
the linked folder but is git-ignored by `config/<app>/.gitignore` (as `config/ssh/.gitignore` does). Per-file links
were rejected: apps that save by writing a temp file and renaming it (common for zed, gh) silently replace a file
link with a regular file.

### 3.5 Port (secret): SOPS-encrypted in the repo

| Entry      | Plain files                                            | SOPS-encrypted files                                              | Owner |
| ---------- | ------------------------------------------------------ | ----------------------------------------------------------------- | :---: |
| `gopass`   | `config`                                               | `age/identities` (and any future file under `config/gopass/age/`) |  OK   |
| `gh`       | `config.yml` (also in §3.4)                            | — (`hosts.yml` git-ignored, see below)                             |  OK   |
| `wakatime` | —                                                      | `.wakatime.cfg` (api key); the rest stays local (§3.6)            |  OK   |
| `gortex`   | `config.yaml` (repo paths of this machine; not secret) | —                                                                 |  OK   |

After review, `gh/hosts.yml` is **not** versioned: it is per machine (who is logged in, keyring or file token;
`install` runs `gh auth login`), and SOPS YAML rewrites gh's `user:` as `user: null`, so it would show as modified
after every gh write. It stays local, git-ignored in `config/gh/.gitignore`.

Folder links here too; `wakatime` state (`.wakatime/`, logs, databases) and `gopass/.fallow/` are git-ignored.

### 3.6 Remove: owner's choice (app still installed, moved aside first)

| Entry     | Files | Notes                                                                                  | Owner  |
| --------- | ----- | -------------------------------------------------------------------------------------- | :----: |
| `vicinae` | 1     | `settings.json`; `vicinae` in `/opt/homebrew/bin`, not in the Brewfile                 | REMOVE |
| `goose`   | many  | **credentials** (OAuth folders, `tls/server.key`); `block-goose` cask, not in the Brewfile | REMOVE |

Both apps stay installed until the owner uninstalls them (`brew uninstall vicinae`, `brew uninstall --cask
block-goose`); if they run again they recreate their folder, which is then unmanaged again. New machines do not get
them (neither is in the Brewfile).

### 3.7 Leave

| Entry             | Why                                           |
| ----------------- | --------------------------------------------- |
| `.fallow` (90M)   | fallow cache (`cache.bin`, `graph-cache.bin`) |
| `github-copilot`  | login database; `copilot` re-authenticates    |
| `wakatime` (rest) | heartbeats, logs, sqlite                      |

## 4. Applying (after approval)

0. **Re-smudge on new machines:** after `setup:git:filters`, the bootstrap task checks out every
   `filter=sops` path again (`git ls-files ':(attr:filter=sops)'`: remove the working copy, `git checkout --`),
   so encrypted files are decrypted on disk; tested on a fresh clone in a container before step 2.
1. **Remove:** delete the 9 links and 8 empty folders; move the §3.3 folders to
   `~/.local/state/dots/config-aside-<YYYYMMDD>/` (owner deletes it after a few weeks). Credential folders
   (`gcloud`, `graphite`, `configstore`, `goose`) are moved, never copied anywhere else. Same for the §3.6 folders.
2. **Port (secret):** per app, one commit: a `.sops.yaml` `creation_rules` entry for the folder (same age
   recipient), `.gitattributes` `config/<app>/<secret path> filter=sops diff=sops`, copy the files, check the
   staged blob is encrypted (`git show :config/<app>/<file> | head -c 40` shows `ENC[` or `"data"`), add the link,
   start the app. For **gopass** also: remove `"~/.config/gopass"` from the history track list, and on every other
   machine replace the real `~/.config/gopass` folder by the link (pull, then `mv` aside and `mise dot apply`).
   Port (plain), per app, one commit: copy the files into `config/<app>/`, add the `dotfiles.toml` entries, replace the
   originals with links (`mise dot apply` or `ln -sfn`), start the app once to confirm it reads the linked file.
3. Update the comment at the top of `dotfiles.toml` if the "Not linked" list changes.

Changes to `~/.config` itself (moves, links) are machine actions run by the owner or with the owner's go-ahead;
the repo changes (config files, `dotfiles.toml`, `config.toml`) are commits.

## 5. Risks

| Risk                                                                               | Mitigation                                                                                                                            |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| A removed app is reinstalled later                                                 | Its folder is in `config-aside-<date>` and in the restic backup                                                                       |
| A ported file contains a secret                                                    | Before each port commit: `gitleaks`/hk pre-commit on the staged file and a manual read                                                |
| A secret file is committed in plain text (filter not configured, path not matched) | `filter.sops.required=true`; folder-wide rules; the staged-blob check in §4 step 2                                                    |
| The public repo holds ciphertext of credentials                                    | Accepted, as for `config/ssh/keys` today: age X25519, key only on the owner's machines and in Bitwarden                               |
| A new machine sees encrypted files                                                 | §4 step 0 re-smudge, tested in a container                                                                                            |
| An app rewrites a linked file (zed)                                       | Edits land in the repo as diffs; review them like any change                                                                          |
| Linux machines                                                                     | Ported entries are macOS-and-Linux safe only if the app exists there; Linux-only gaps are fine (a link to an unused file is harmless) |

## 6. Done when

1. Every §3 row has an owner verdict.
2. `ls -A ~/.config` shows only: links into `config/`, `ssh`, `gnupg`, §3.7 entries, and `glow`, `opencode`,
   `raycast` (in `config/` but real folders on this Mac, never linked: out of this audit's scope).
   `~/.config/gopass` is a link, and `gopass show -o tokens/age.dots.github.com </dev/null` prints.
3. `hk check` clean; `mise dot status` (or `mise bootstrap status`) reports no pending changes.
