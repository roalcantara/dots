# One packages.toml for every package — design

Status: approach approved by the owner (2026-11-05): **one `config/mise/conf.d/packages.toml`**, everything under
`[bootstrap.packages]`, using mise's built-in managers plus three small in-repo package-manager plugins
(`cask:`, `uv:`, `npm:`) that call real Homebrew, uv and npm. It replaces `config/homebrew/Brewfile` (#92).

## 1. Goal and done criteria

1. `config/mise/conf.d/packages.toml` is the only list of packages; `config/homebrew/Brewfile` and
   `config/mise/conf.d/system.toml` are gone (system.toml's entries move into packages.toml).
2. uv and npm packages keep **one version each**, upgraded in place, with brew-style paths (`~/.local/bin` for uv
   tools, Homebrew's `bin` for npm globals) — the owner's reason for not using mise `[tools]` (mise keeps every
   installed version: this Mac holds 7 `pipx:commit-check` versions, 4.8 GB under `mise/installs`).
3. Casks needed on both OSes (zed, claude-code, codex, copilot-cli@prerelease, github-copilot-app) install on Linux
   too: real Homebrew supports them there; mise's `brew-cask:` does not.
4. `mise bootstrap -E desktop` on this Mac installs nothing new; on the Ubuntu VM it installs the desktop set.
5. Containers still get only the minimal set; images build and pass the CST.
6. `mise run test:specs`, `hk check --all` green; the CI Preview workflow passes.

## 2. Findings (2026-11-05)

| Finding | Evidence |
| --- | --- |
| #92 moved packages to the Brewfile because mise's `brew:` could not install uv/pipx tools | #92 design §2 |
| `[bootstrap.packages]` skips managers a machine lacks: `"apt:git" = "latest"` needs no `os` key | owner's test on `fix/linux-desktop-parity` (`system.toml`) |
| mise's `brew-cask:` on Linux installs **only font casks**; other casks show `skipped` | mise docs, brew-cask: "On Linux, `brew-cask` installs only font casks…"; "mise never falls back to running `brew`" |
| Real Homebrew installs zed, claude-code, codex, copilot-cli, github-copilot-app on Linux | the VM run with the Brewfile (`e7a3c62` drops `if OS.mac?`) |
| mise `[tools]` keeps old versions: `latest` installs new versions without an upgrade, so `upgrade.auto_prune` never runs | `mise ls --installed` on this Mac |
| A package-manager plugin is Lua: `PackageInstalled` (read-only) and `PackageInstall` hooks, `requires` host programs, no `sudo`, raise on failure; declared under `[bootstrap.plugins]`, referenced as `"<name>:<pkg>"`; names cannot be built-in managers | mise package plugin docs |
| The Brewfile today | 3 taps (3 `trusted: true` entries + 1 cask from `xykong/tap`), 87 `brew`, 27 `cask`, 1 `flatpak`, 3 `uv`, 3 `npm`; a minimal group above `return unless desktop` |

## 3. Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| File | `config/mise/conf.d/packages.toml`, one `[bootstrap.packages]` table | One place, mise-native syntax the owner already tested |
| Profiles | No `env` key → every profile (the minimal container set); `{ env = "desktop" }` → desktops | Same split as the Brewfile's `return unless desktop` |
| OS limits | `os = "macos"` (or `"linux"`) only for a `brew:` formula that exists on one OS (today's `brew "…" if OS.mac?`); casks, flatpaks and apt need none (the manager decides). Discord (x86_64 only): per spike S5 | Replaces `if OS.mac?` |
| Formulae | Built-in `brew:` | Native, no Ruby process; same Cellar |
| macOS-only casks, fonts | Built-in `brew-cask:` | Fonts install on Linux too (`~/.local/share/fonts`) |
| Casks on both OSes | Plugin `cask:` → `brew install --cask` / `brew upgrade --cask` | Real Homebrew is the only installer that supports them on Linux |
| uv tools | Plugin `uv:` → `uv tool install` / `uv tool upgrade` | One version, `~/.local/bin` |
| npm globals | Plugin `npm:` → `npm install -g <pkg>@latest` | One version, Homebrew's prefix |
| Homebrew itself | Installed by a **`pre-packages`** hook (was `post-packages`) | `cask:` needs `brew` before packages run |
| Rejected: mise `[tools]` (`pipx:`, `npm:`) | — | Version pile-up and shim paths (owner) |
| Rejected: npm/flatpak substitutes for Linux casks | — | Two entries per app (owner) |
| Rejected: keep the Brewfile | — | Two package files; Ruby `brew bundle` run |

## 4. Components

### 4.1 `config/mise/conf.d/packages.toml`

```toml
[bootstrap.brew.taps]
"asmvik/formulae" = "https://github.com/asmvik/homebrew-formulae.git"
"can1357/tap" = "https://github.com/can1357/homebrew-tap.git"
"oven-sh/bun" = "https://github.com/oven-sh/homebrew-bun.git"
"xykong/tap" = "https://github.com/xykong/homebrew-tap.git"

[bootstrap.plugins]
cask = { path = "~/.local/share/dots/config/mise/plugins/cask" }   # exact key per spike S4
uv = { path = "~/.local/share/dots/config/mise/plugins/uv" }
npm = { path = "~/.local/share/dots/config/mise/plugins/npm" }

[bootstrap.packages]
# Every profile (containers too): Homebrew's Linux prerequisites, the minimal shell set
"apt:build-essential" = "latest"
"brew:zoxide" = "latest"
# … fzf eza bat ripgrep fd jq neovim git-delta
# Desktop
"brew:gh" = { env = "desktop" }
"brew-cask:ghostty" = { env = "desktop" }                # macOS-only cask: skipped on Linux
"brew-cask:font-cascadia-code" = { env = "desktop" }     # fonts: both OSes
"cask:zed" = { env = "desktop" }                          # real brew: both OSes
"uv:pynvim" = { env = "desktop" }
"npm:react-devtools" = { env = "desktop" }
"flatpak:com.bitwarden.desktop" = { env = "desktop" }     # Linux only (no flatpak on macOS)
```

Order and grouping follow today's Brewfile sections; each entry keeps its trailing comment.

### 4.2 Plugins: `config/mise/plugins/{cask,uv,npm}/`

Each: `metadata.lua` (`PLUGIN = { name = "…" }`), `mise.plugin.toml` (`[package-manager] requires = […]`),
`hooks/package_installed.lua`, `hooks/package_install.lua`. No `sudo`; a failing command raises.

| Plugin | requires | PackageInstalled (read-only) | PackageInstall |
| --- | --- | --- | --- |
| `cask` | `brew` | `brew list --cask --versions` | `brew install --cask <pkgs>`; installed-but-outdated → `brew upgrade --cask <pkg>` |
| `uv` | `uv` | `uv tool list` | `uv tool install <pkg>` (missing) / `uv tool upgrade <pkg>` |
| `npm` | `npm` | `npm ls -g --depth=0 --json` | `npm install -g <pkg>@latest` |

Versions: entries use `"latest"`; plugins set `supports_version_pins = false`.

### 4.3 Bootstrap flow (`config/mise/conf.d/bootstrap.toml`)

- `pre-packages` hook: install Homebrew if missing (the current install block, moved), put `brew shellenv` on
  `PATH`.
- Removed: the brew-bundle `post-packages` hook (two-stage bundle, `brew-bundle.failed`/`.log`, `DOTS_STRICT`),
  the bootstrap task's `remind` trap for it, `HOMEBREW_DOTS_PROFILE`, `HOMEBREW_BUNDLE_FILE` exports.
- Failure policy: per spike S2. If mise stops on one failed package, the pre-#94 problem returns; the fallback is
  `--keep-going`-style setting if mise has one, else documenting `mise bootstrap packages apply` re-runs.

### 4.4 Other references

`README.md`, `AGENTS.md`, `docs/{DOCKER,REINSTALL}.md`, `config/zsh/opt/rc.d/env.zsh`, `config/bash/bashrc`,
`config/vscode/settings.json`, `config/restic/backup.toml`, `script/backup.ts`, the two CSTs and
`.github/workflows/preview.yml` (the "Brewfile parses" job → "packages.toml parses":
`mise bootstrap packages status` for both profiles).

## 5. Spikes (Task 1, before any change)

In a throwaway Ubuntu container (arm64) and on this Mac, with a scratch config:

| # | Question | Pass | If it fails |
| --- | --- | --- | --- |
| S1 | Does one `mise bootstrap packages apply` install `brew:uv`/`brew:node` **before** running plugins that `require` them? | `uv:`/`npm:` entries install in a first run on a clean machine | Run `mise bootstrap packages apply` a second time from the bootstrap task, or install uv/node in `pre-packages` |
| S2 | Does one failing package stop the run? | Others install; the failure is reported, exit non-zero at the end | Find mise's continue-on-error option; else keep a wrapper |
| S3 | Do taps with `trusted: true` (Homebrew 7) need anything in `[bootstrap.brew.taps]`? | `brew:oven-sh/bun/bun` installs | Use the documented trust key |
| S4 | The exact `[bootstrap.plugins]` syntax for an in-repo plugin path | `mise bootstrap packages status` lists `cask:`/`uv:`/`npm:` entries | Link with `mise plugins link <name> <path>` in `pre-packages` |
| S5 | `arch`-specific entries (Discord x86_64 only) | an `arch` key, or `os` + comment | keep it with a comment |

## 6. Testing

- `test/integration/packages/plugins.spec.ts`: each plugin's hooks run against stub `brew`/`uv`/`npm` on `PATH`
  (how to run Lua hooks: via `mise bootstrap packages status|apply` with a scratch config pointing at the plugin,
  per S4): installed/missing detection, install vs upgrade commands, a failing command raises.
- `test/integration/packages/packages-toml.spec.ts`: packages.toml parses (`Bun.TOML.parse`); every entry is
  `"<known manager>:<name>"`; no duplicate package across managers; the minimal (no `env`) set equals the
  container CST's expected tools.
- Remove `test/integration/bootstrap/post-packages.spec.ts`.
- Container: `mise run build --local --distro ubuntu` + CST (AGENTS.md gate).
- VM: the owner runs `install` on a fresh Ubuntu VM.

## 7. Risks

| Risk | Mitigation |
| --- | --- |
| Plugin ordering (S1) or failure policy (S2) is worse than `brew bundle` | Spikes first; stop and report if no workaround |
| mise's native `brew:` differs from Homebrew for a formula (post-install steps) | Spike with the desktop set on the VM; such formulae move to `cask:`-style real-brew handling only if needed |
| Existing machines have formulae installed by real Homebrew | Same Cellar; `mise bootstrap packages status` shows them installed |
| Memory on the VM (owner report) | Out of scope: measure with `ps aux --sort=-%mem` after this lands (skills restore and `docker.io` are likelier causes) |

## 8. Out of scope

`config/.profile` `XDG_RUNTIME_DIR` (separate fix, `fix/profile-runtime-dir`); Ghostty on Linux (dropped by the
owner); memory investigation; Windows.
