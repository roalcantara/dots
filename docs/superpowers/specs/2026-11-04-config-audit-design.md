# ~/.config audit — design

Status: approach approved by the owner (2026-11-04): a one-off review, **no guard** (no unmanaged list, no audit
section). Port rule: **installed and customized**.

Revised (owner, 2026-11-04): **one way of handling things**. Every kept entry is a link from `~/.config/<app>` to
`config/<app>`; files that hold secrets are committed **SOPS-encrypted**, by a rule covering the app's whole
folder (as `config/ssh/keys/*.key` and `config/.env` already are). gopass moves out of the encrypted history into
`config/gopass`. Exceptions kept in the history this round: `goose` (OAuth tokens refresh often: each refresh would
be a repo change), `ssh`, `gnupg` (permissions; a separate change).

## 1. Goal

Every entry in `~/.config` that is not in `config/` ends in exactly one place:

| Verdict | Meaning | Where it lands |
| --- | --- | --- |
| **Port** | App installed, settings customized, no secrets | `config/<app>/`, linked by `config/mise/conf.d/dotfiles.toml` |
| **Port (secret)** | As Port, but some files hold a credential | `config/<app>/`, linked; secret files committed SOPS-encrypted (`.gitattributes` `filter=sops diff=sops` + a `.sops.yaml` rule for the folder) |
| **Track** | Exception only: secret files an app rewrites often | `[dotfiles]` entry with `mode = "track", encrypt = true` in `config/mise/config.toml` |
| **Leave** | Cache or state the app writes and recreates | Untouched |
| **Remove** | Broken link, empty folder, or app not installed | Deleted; non-empty folders are first moved to `~/.local/state/dots/config-aside-<date>/` |

Already correct, out of scope: `kb` (link to `config/kodexb`). Unchanged this round: `ssh`, `gnupg` (tracked,
encrypted; `config/ssh` also exists in the repo, so ssh is handled twice: a follow-up).

## 2. Evidence method (2026-11-04, this Mac)

- Installed: per-app lookup (formula, cask, `/Applications/<App>.app`, `command -v`); a mise shim counts.
- Files, size, last change: `find`, `du -sh`, `stat`.
- Secrets: file names and key-name patterns (`token|secret|password|api_key|oauth|private_key`) only; no value is
  printed or copied.
- Customized: hand-written content beyond the app's generated default (comments, keymaps, settings changed).

Verified for the revised approach (2026-11-04, throwaway `HOME`, gopass 1.17.4, test key only):

| Check | Result |
| --- | --- |
| gopass with `~/.config/gopass` a link to a repo-like `config/gopass` | read ✓; insert and `gopass config` write through it ✓; stays a link ✓ |
| `sops encrypt --input-type binary` of the X25519 `identities` file, then decrypt | JSON envelope; decrypted file identical byte for byte ✓ |
| `script/clean.sops.sh` / `smudge.sops.sh` | infer the type from `--filename-override`: no extension → binary (as `*.key` today), `.yml` → YAML values |

Gap found: `install` clones the repo **before** the age key and `setup:git:filters` exist, and `setup:git:filters`
only sets git config, so SOPS files stay encrypted in the working tree of a new machine (§4 step 0).

## 3. Inventory and proposed verdicts

Owner: mark **OK** or write the verdict you want in the last column. Nothing changes on disk before this table is
approved.

### 3.1 Remove: broken links (9)

Targets deleted from the repo earlier (closeout #95, packages #92, or never committed).

| Entry | Target | Owner |
| --- | --- | --- |
| `amethyst` | `config/amethyst` (closeout) | |
| `bunfig.toml` | `~/Work/dots/config/bunfig.toml` (absolute link; never in git) | |
| `cursor` | `config/cursor` (closeout) | |
| `glide` | `config/glide` (closeout) | |
| `ranma` | `config/ranma` (closeout) | |
| `rift` | `config/rift` (closeout) | |
| `skhd` | `config/skhd` (closeout) | |
| `starship` | `config/starship` (#92) | |
| `tealdeer` | `config/tealdeer` (never in git; `brew "tealdeer"` stays, it works without a config) | |

### 3.2 Remove: empty folders (8)

`act`, `crewai`, `crush`, `devin`, `firebase`, `obsidian`, `rclone`, `swiftpm`: 0 bytes each.

Owner (all 8):

### 3.3 Remove: app not installed (moved aside first)

| Entry | Files | Notes | Owner |
| --- | --- | --- | --- |
| `.agents` | 1 skill dir | `yabai-skhd-doctor` skill; yabai/skhd removed | |
| `skills-lock.json` | 1 | Lock for that one skill only | |
| `.DS_Store` | 1 | Finder metadata | |
| `.rz` | 994 | `rz` not installed; plugin repo clones (cache) plus `config.toml` | |
| `.semgrep` | 1 | `semgrep` not installed | |
| `acli` | 8 | Atlassian CLI not installed | |
| `aegis` | 4 | yabai helper scripts; yabai removed | |
| `amp` | 1 | Amp plugin; `amp` not installed | |
| `AWSVPNClient` | 5 | AWS VPN Client not installed; connection profiles inside | |
| `cagent` | 2 | first-run marker, user uuid | |
| `configstore` | 2 | firebase-tools state (**credential**); firebase not installed | |
| `crossnote` | 4 | crossnote not installed | |
| `gcloud` | 2120 | **credentials** (`application_default_credentials.json`, `legacy_credentials/`); gcloud not installed | |
| `ghostex` | 3 | Ghostex not installed | |
| `gitlint` | 1 | gitlint not installed | |
| `graphite` | 3 | **credential** (`auth`); `gt` not installed | |
| `karabiner` | 2 | Karabiner-Elements not installed | |
| `KiwiDesk` | 5 | KiwiDesk not installed | |
| `macterm` | 1 | MacTerm not installed | |
| `marp` | 39 | marp-cli not installed (7.1M) | |
| `nx` | 1 | `nx` not installed | |
| `openspec` | 1 | `openspec` not installed | |
| `presenterm` | 1 | presenterm not installed | |
| `puppeter` | 1 | Misspelled folder: Puppeteer never reads it | |
| `reveal-md` | 1 | reveal-md not installed | |
| `sketchybar` | 6 | sketchybar not installed | |

### 3.4 Port (installed, customized, no secrets)

| Entry | Port | Exclude (stays local) | Owner |
| --- | --- | --- | --- |
| `zed` | `settings.json` (187 lines), `keymap.json` (217), `themes/` (empty: skip) | `conversations/`, `prompts/` (database), `keymap_backup.json` | |
| `zentty` | `config.toml` (102 lines), `bookmarks.json` | `restore-*.json`, `run/` | |
| `dprint` | `dprint.jsonc` (63 lines, global config) | — | |
| `posting` | `config.yaml` (38 lines) | — | |
| `vicinae` | `settings.json` (26 lines) | — (vicinae may write to it: port only if it is hand-edited, else Leave) | |
| `gh` | `config.yml` (aliases, settings) | `hosts.yml` (token: SOPS, §3.5) | |

`zed`, `zentty` and `gh` mix ported files with local state, so they use per-file links
(`"~/.config/zed/settings.json" = …`), not a folder link.

### 3.5 Port (secret): SOPS-encrypted in the repo

| Entry | Plain files | SOPS-encrypted files | Owner |
| --- | --- | --- | --- |
| `gopass` | `config` | `age/identities` (and any future file under `config/gopass/age/`) | |
| `gh` | `config.yml` (also in §3.4) | `hosts.yml` (token) | |
| `wakatime` | — | `.wakatime.cfg` (api key); the rest stays local (§3.6) | |
| `gortex` | `config.yaml` (repo paths of this machine; not secret) | — | |

`gh` and `wakatime` keep local state next to the ported files, so they use per-file links. `gopass` is a folder
link: everything in it is either plain config or encrypted.

### 3.6 Track (exception: encrypted history)

| Entry | What | Why not the repo | Owner |
| --- | --- | --- | --- |
| `goose` | `config.yaml`, `gemini_oauth/`, `xai_oauth/`, `chatgpt_codex/`, `tls/` (exclude `mcp-apps-cache/`) | OAuth tokens refresh often; each refresh would be a commit | |

### 3.7 Leave

| Entry | Why |
| --- | --- |
| `.fallow` (90M) | fallow cache (`cache.bin`, `graph-cache.bin`) |
| `github-copilot` | login database; `copilot` re-authenticates |
| `wakatime` (rest) | heartbeats, logs, sqlite |

## 4. Applying (after approval)

0. **Re-smudge on new machines:** after `setup:git:filters`, the bootstrap task checks out every
   `filter=sops` path again (`git ls-files ':(attr:filter=sops)'`: remove the working copy, `git checkout --`),
   so encrypted files are decrypted on disk; tested on a fresh clone in a container before step 3.
1. **Remove:** delete the 9 links and 8 empty folders; move the §3.3 folders to
   `~/.local/state/dots/config-aside-<YYYYMMDD>/` (owner deletes it after a few weeks). Credential folders
   (`gcloud`, `graphite`, `configstore`) are moved, never copied anywhere else.
2. **Track:** add `goose` (§3.6) to `config/mise/config.toml` `[dotfiles]` with `mode = "track", encrypt = true`
   and its `exclude`; `mise dot save` records it.
3. **Port (secret):** per app, one commit: a `.sops.yaml` `creation_rules` entry for the folder (same age
   recipient), `.gitattributes` `config/<app>/<secret path> filter=sops diff=sops`, copy the files, check the
   staged blob is encrypted (`git show :config/<app>/<file> | head -c 40` shows `ENC[` or `"data"`), add the link,
   start the app. For **gopass** also: remove `"~/.config/gopass"` from the history track list, and on every other
   machine replace the real `~/.config/gopass` folder by the link (pull, then `mv` aside and `mise dot apply`).
   Port (plain), per app, one commit: copy the files into `config/<app>/`, add the `dotfiles.toml` entries, replace the
   originals with links (`mise dot apply` or `ln -sfn`), start the app once to confirm it reads the linked file.
4. Update the comment at the top of `dotfiles.toml` if the "Not linked" list changes.

Changes to `~/.config` itself (moves, links) are machine actions run by the owner or with the owner's go-ahead;
the repo changes (config files, `dotfiles.toml`, `config.toml`) are commits.

## 5. Risks

| Risk | Mitigation |
| --- | --- |
| A removed app is reinstalled later | Its folder is in `config-aside-<date>` and in the restic backup |
| A ported file contains a secret | Before each port commit: `gitleaks`/hk pre-commit on the staged file and a manual read |
| A secret file is committed in plain text (filter not configured, path not matched) | `filter.sops.required=true`; folder-wide rules; the staged-blob check in §4 step 3 |
| The public repo holds ciphertext of credentials | Accepted, as for `config/ssh/keys` today: age X25519, key only on the owner's machines and in Bitwarden |
| A new machine sees encrypted files | §4 step 0 re-smudge, tested in a container |
| An app rewrites a linked file (vicinae, zed) | Edits land in the repo as diffs; review them like any change |
| Linux machines | Ported entries are macOS-and-Linux safe only if the app exists there; Linux-only gaps are fine (a link to an unused file is harmless) |

## 6. Done when

1. Every §3 row has an owner verdict.
2. `ls -A ~/.config` shows only: links into `config/`, `goose`, `ssh`, `gnupg`, and §3.7 entries.
   `~/.config/gopass` is a link, and `gopass show -o tokens/age.dots.github.com </dev/null` prints.
3. `hk check` clean; `mise dot status` (or `mise bootstrap status`) reports no pending changes.
