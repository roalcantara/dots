# ~/.config audit — design

Status: approach approved by the owner (2026-11-04): a one-off review, **no guard** (no unmanaged list, no audit
section). Port rule: **installed and customized**; anything holding a credential goes to the encrypted history.

## 1. Goal

Every entry in `~/.config` that is not in `config/` ends in exactly one place:

| Verdict | Meaning | Where it lands |
| --- | --- | --- |
| **Port** | App installed, settings customized, no secrets | `config/<app>/`, linked by `config/mise/conf.d/dotfiles.toml` |
| **Track** | Needed on a new machine but holds a credential or machine-specific paths | `[dotfiles]` entry with `mode = "track", encrypt = true` in `config/mise/config.toml`, like gopass |
| **Leave** | Cache or state the app writes and recreates | Untouched |
| **Remove** | Broken link, empty folder, or app not installed | Deleted; non-empty folders are first moved to `~/.local/state/dots/config-aside-<date>/` |

Already correct, out of scope: `gnupg`, `gopass` (tracked, encrypted), `kb` (link to `config/kodexb`).

## 2. Evidence method (2026-11-04, this Mac)

- Installed: per-app lookup (formula, cask, `/Applications/<App>.app`, `command -v`); a mise shim counts.
- Files, size, last change: `find`, `du -sh`, `stat`.
- Secrets: file names and key-name patterns (`token|secret|password|api_key|oauth|private_key`) only; no value is
  printed or copied.
- Customized: hand-written content beyond the app's generated default (comments, keymaps, settings changed).

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
| `gh` | `config.yml` (aliases, settings) | `hosts.yml` (token: Track) | |

`zed`, `zentty` and `gh` mix ported files with local state, so they use per-file links
(`"~/.config/zed/settings.json" = …`), not a folder link.

### 3.5 Track (encrypted history)

| Entry | What | Why not port | Owner |
| --- | --- | --- | --- |
| `gh/hosts.yml` | GitHub login | token | |
| `goose` | `config.yaml`, `gemini_oauth/`, `xai_oauth/`, `chatgpt_codex/`, `tls/` (exclude `mcp-apps-cache/`) | OAuth tokens, TLS key | |
| `wakatime/.wakatime.cfg` | API key, settings | `api_key` | |
| `gortex/config.yaml` | repo list | absolute paths of this machine | |

### 3.6 Leave

| Entry | Why |
| --- | --- |
| `.fallow` (90M) | fallow cache (`cache.bin`, `graph-cache.bin`) |
| `github-copilot` | login database; `copilot` re-authenticates |
| `wakatime` (rest) | heartbeats, logs, sqlite |

## 4. Applying (after approval)

1. **Remove:** delete the 9 links and 8 empty folders; move the §3.3 folders to
   `~/.local/state/dots/config-aside-<YYYYMMDD>/` (owner deletes it after a few weeks). Credential folders
   (`gcloud`, `graphite`, `configstore`) are moved, never copied anywhere else.
2. **Track:** add the §3.5 entries to `config/mise/config.toml` `[dotfiles]` with `mode = "track", encrypt = true`
   (and `exclude` for goose); `mise dot save` records them.
3. **Port:** per app, one commit: copy the files into `config/<app>/`, add the `dotfiles.toml` entries, replace the
   originals with links (`mise dot apply` or `ln -sfn`), start the app once to confirm it reads the linked file.
4. Update the comment at the top of `dotfiles.toml` if the "Not linked" list changes.

Changes to `~/.config` itself (moves, links) are machine actions run by the owner or with the owner's go-ahead;
the repo changes (config files, `dotfiles.toml`, `config.toml`) are commits.

## 5. Risks

| Risk | Mitigation |
| --- | --- |
| A removed app is reinstalled later | Its folder is in `config-aside-<date>` and in the restic backup |
| A ported file contains a secret | Before each port commit: `gitleaks`/hk pre-commit on the staged file and a manual read |
| An app rewrites a linked file (vicinae, zed) | Edits land in the repo as diffs; review them like any change |
| Linux machines | Ported entries are macOS-and-Linux safe only if the app exists there; Linux-only gaps are fine (a link to an unused file is harmless) |

## 6. Done when

1. Every §3 row has an owner verdict.
2. `ls -A ~/.config` shows only: repo links, tracked entries, and §3.6 entries.
3. `hk check` clean; `mise dot status` (or `mise bootstrap status`) reports no pending changes.
