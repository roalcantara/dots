# Replacing `install` with `mise bootstrap`

Date: 2026-10-28. mise 2026.10.21. Scope: macOS (Apple Silicon) and Debian/Ubuntu hosts and containers.

## Verdict

**Adopt it.** `mise bootstrap` covers everything `install` does that still matters, and needs one tool
instead of five: mise installs Homebrew bottles itself ("mise never runs `brew`"), so neither Homebrew nor
flox is needed. Linux keeps its own package managers (`apt`, `flatpak`) only for what Homebrew cannot
deliver there. The 842-line script becomes a declarative config of roughly 250–300 lines plus a short
`bootstrap` task.

**Effort: medium, about 3 days**, mostly verification (see [Effort](#effort)).

## What `install` does today

Eight steps, run in order (`install:833-840`):

| # | Step | Does |
|---|---|---|
| 1 | `setup_system` | Detects OS/arch/container; parses `-u -g -t -p -r -b -e`; `apt` installs `sudo git wget unzip ca-certificates gnupg zsh` and enables `universe`; sets the timezone (Linux) |
| 2 | `setup_user_home_and_dotfiles` | Creates user and group (`dscl` on macOS, `useradd` on Linux, password policy, sudoers in containers); moves old dotfiles to `~/.local/share/backup/<date>`; creates XDG and tool dirs; clones `dots` to `~/.local/share/dots`; links `~/.config`, `.zshenv`, `.profile`; links each executable in `config/bin` into `~/.local/bin` |
| 3 | `setup_user_context` | `chown -R` of `$HOME` |
| 4–5 | `setup_package_manager`, `setup_packages` | Installs flox and its packages (**obsolete**) |
| 6 | `setup_tools` | Login shell to zsh; `USER_ZDOTDIR` in `/etc/zsh/zshenv`; Neovim providers (npm, Python venv, gem) and headless `Lazy sync`; links `hk`/`cog` configs and runs `mise run setup:hooks` |
| 7 | `setup_operation_system` | Hosts only. macOS: `brew bundle` on the Brewfile. Linux: flatpak (10), snap (2), apt (1) lists, Ollama (`curl \| sh`), Docker Desktop (apt repo + key), Nerd Fonts |
| 8 | `setup_ownership` | `chown -R` again |

Already broken or stale: flox (steps 4–5, 50 files in the repo), `-p` accepts only `flox`,
`task_add_linux_nerd_fonts` is called but never defined, and step 2 links all of `~/.config` while this
Mac links 35 folders one by one.

## Mapping to `mise bootstrap`

| `install` | `mise bootstrap` | Notes |
|---|---|---|
| Clone `dots`, find config | `mise bootstrap --from <repo> --from-dir ~/.local/share/dots --config-dir config/mise` | One command clones the repo and links `~/.config/mise` into it; later runs reuse the checkout (`--update` pulls) |
| OS/arch/container detection, flags | `os = …` on entries; `MISE_ENV` / `-E container` for container profiles; `--only` / `--skip` | `-u -g -t -p -r -b -e` disappear |
| `apt` base packages, `universe` | `"apt:zsh"` … in `[bootstrap.packages]`; `[bootstrap.apt.sources]` | Uses `sudo` itself when not root |
| Brewfile: 84 formulae + 4 taps | `"brew:…"` + `[bootstrap.brew.taps]`; `mise bootstrap packages import -g` | Dry run on this Mac: **86 formulae and 4 taps generated automatically** |
| Brewfile: 38 casks | `"brew-cask:…" = { os = "macos" }` | Not covered by `import`; a one-line `sed` per Brewfile line |
| Brewfile: 9 `go`, 3 `uv` | `[tools]` with `go:` and `pipx:` backends | Already the mise way |
| flatpak (10) | `"flatpak-user:…" = { os = "linux" }` | |
| snap (2) | Drop, or replace with flatpak/brew | Keeps the toolset minimal |
| Ollama `curl \| sh` | `"brew:ollama"` | Bottles exist on Linux |
| Docker Desktop (Linux) | `[bootstrap.apt.sources]` + `"apt:docker-desktop"` | Repo and key become declarative |
| Nerd Fonts (undefined) | `"brew-cask:font-…-nerd-font" = { os = ["linux", "macos"] }` | Font casks work on Linux too: fixes the bug |
| Links into `~/.config`, `.zshenv`, `.profile`, `.ssh`, `.gnupg` | `[dotfiles]` entries, `symlink` mode | One entry per linked folder |
| `config/bin/*` into `~/.local/bin` | `[dotfiles]` `symlink-each` | |
| Backup of old dotfiles | Dotfile checkpoints; `mise dot undo` | Replaces `~/.local/share/backup/<date>` |
| XDG and tool directories | `[bootstrap.directories]` | |
| Login shell to zsh | `[bootstrap.user]` | |
| `/etc/zsh/zshenv` `USER_ZDOTDIR` (Linux) | `[bootstrap.files]` block edit, `os = "linux"` | |
| Timezone (Linux containers) | `[bootstrap.files]` or a hook | Containers can also set `TZ` in the Dockerfile |
| Linux user, group, sudoers (containers) | `[bootstrap.users]`, `[bootstrap.groups]`, `[bootstrap.files]` | Linux only (see gaps) |
| Neovim providers, `Lazy sync`, `setup:hooks` | `[tasks.bootstrap]` | Runs every time: must stay idempotent |
| GitHub token lookup | `GITHUB_TOKEN` in the environment, or `fnox` (already in `[tools]`) | |
| `chown -R $HOME` | Not needed | Everything runs as the user |

## Gaps and risks

| Item | Impact | Mitigation |
|---|---|---|
| `accounts` is Linux-only: no `dscl` user creation on macOS | Low: a new Mac already has its user from Setup Assistant | Drop it on macOS |
| Native Homebrew: no `brew services`, some post-install steps skipped, unbottled formulae build from source | Low: yabai-style services start through their own commands or `[bootstrap.macos.launchd.agents]` | Check the few formulae with services; keep Homebrew only if one fails |
| Casks on Linux are fonts only | GUI apps on Linux come from flatpak | Already the case today |
| Not transactional; hooks and the task rerun every time | A failure leaves partial changes; rerun is the fix | Idempotent task; `--dry-run`, `status`, `plan` before applying |
| New feature, moving fast | Config keys may change between releases | Pin mise in the bootstrap one-liner; re-run `mise bootstrap status` after upgrades |

## New-machine flow

```sh
curl https://mise.run | sh
~/.local/bin/mise bootstrap --from https://github.com/roalcantara/dots \
  --from-dir ~/.local/share/dots --config-dir config/mise
```

Containers: the same command with `-E container`, or `--skip` for host-only parts (casks, flatpak, macOS
defaults).

## Effort

| Work | Size |
|---|---|
| Packages: run `import`, convert 38 casks, move `go`/`uv` to `[tools]`, flatpak, apt basics, Docker repo, fonts | 3–4 h |
| Dotfiles: ~40 `symlink` entries, `config/bin` `symlink-each`, directories | 2–3 h |
| Linux system parts: users, groups, sudoers, `/etc/zsh/zshenv`, timezone, login shell | 2–3 h |
| `[tasks.bootstrap]`: Neovim providers, `Lazy sync`, `setup:hooks` | 1 h |
| `distros/*/Dockerfile`, `README.md`, `DOCKER_GUIDE.md`, `AGENTS.md`; delete `install`, `config/flox`, `purge_flox` | 3–4 h |
| Verification: `status`/`plan` on this Mac, Debian and Ubuntu images, a fresh macOS install | 1 day |
| **Total** | **about 3 days** |

The planned macOS reinstall is the natural first real run: write the config and check it with
`mise bootstrap status` and `--dry-run` on this Mac before wiping it, and keep `install` and the Brewfile
in the repo until the fresh machine is up.
