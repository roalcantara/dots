# dots

[![Preview](https://github.com/roalcantara/dots/actions/workflows/preview.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/preview.yml)

Sets up a machine — shell, editor, packages, secrets and agent skills — from one declarative
[mise](https://mise.jdx.dev) config, on macOS, Debian/Ubuntu and containers.

> Last reviewed: 2026-11-04

## Install

On a fresh macOS or Debian/Ubuntu machine (macOS: run `xcode-select --install` first, for `git`):

```sh
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash
```

[`install`](install) then:

1. installs `git` (Linux, if missing) and the pinned mise;
2. clones this repo into `~/.local/share/dots`;
3. asks for the age key (hidden input; keep it in your password manager);
4. signs `gh` in to GitHub (a browser device flow);
5. runs `mise bootstrap --adopt`, which restores the encrypted secrets from the private `dots-history` repo;
6. links `~/.config/mise` to `config/mise/` and records the profile in `config/mise/miserc.local.toml`;
7. runs `mise bootstrap -E <profile>`: packages, links, directories, login shell and the `bootstrap` task.

It creates no user and sets no timezone. A second run changes nothing.

| Variable       | Default                                           |                                                               |
| -------------- | ------------------------------------------------- | ------------------------------------------------------------- |
| `DOTS_PROFILE` | `desktop`                                         | Which profile to apply (below)                                |
| `DOTS_BRANCH`  | `main`                                            | Branch to clone; to try a branch, fetch `install` from it too |
| `DOTS_REPO`    | `https://github.com/roalcantara/dots.git`         | Repository to clone                                           |
| `DOTS_HISTORY` | `https://github.com/roalcantara/dots-history.git` | Encrypted history to restore                                  |
| `DOTS_AGE_KEY` | —                                                 | The key itself, for tests; otherwise it is prompted           |

| Profile        | For                  | Skips                                                                                               |
| -------------- | -------------------- | --------------------------------------------------------------------------------------------------- |
| `desktop`      | A real machine       | The dev tools (below); moves an existing `~/.bashrc`, `~/.profile`, `~/.zshenv`, `~/.ssh`, `~/.gnupg` aside first |
| `container`    | Docker images        | The login shell; replaces the image's dotfiles                                                      |

`install` sets up **desktop**: the shell, secrets, browsers, terminal, fonts and everyday apps. Add the development
tools when you need them, from any folder in your home:

```sh
mise run setup dev       # desktop + dev: the Brewfile's DEVTOOLS section, agent skills, Python 3.13 tools
mise run setup desktop   # back to desktop (uninstalls nothing; the dev tools just stop being updated)
```

| Profile            | Brewfile                                   | Bootstrap task adds                               |
| ------------------ | ------------------------------------------ | ------------------------------------------------- |
| `container`        | the minimal group                          | git filters only                                  |
| `desktop`          | minimal + everything above `# DEVTOOLS`    | hooks, gopass store, Neovim providers and plugins |
| `desktop,dev`      | + the `# DEVTOOLS` section                 | + agent skills restore, + Python 3.13 tools       |

`setup` records the choice in `config/mise/miserc.local.toml`. Later, to apply config changes: `mise bootstrap`
(it uses the recorded profile).

## How it works

`install` prepares the machine and hands over to `mise bootstrap`. mise reads `~/.config/mise`, which links to
`config/mise/` in this repo, so editing a file there and re-running `mise bootstrap` applies it.

| File                                                                     | Holds                                                                                                                                                              |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`config/mise/config.toml`](config/mise/config.toml)                     | Settings, the encrypted history (`[dotfiles]` track entries), and the `backup` task                                                                               |
| [`config/homebrew/Brewfile`](config/homebrew/Brewfile)                   | Every user package: formulae, casks, taps, `uv` tools, Flatpak apps. `HOMEBREW_DOTS_PROFILE=container` gets only the first group                                 |
| [`config/mise/conf.d/system.toml`](config/mise/conf.d/system.toml)       | apt packages Homebrew needs on Linux                                                                                                                               |
| [`config/mise/conf.d/bootstrap.toml`](config/mise/conf.d/bootstrap.toml) | Directories, system files, the login shell, and the `bootstrap` task (git filters, hooks, gopass store, oMLX models, agent skills, Neovim)                         |
| [`config/mise/conf.d/dotfiles.toml`](config/mise/conf.d/dotfiles.toml)   | Links from `~/.config/*` into this repo                                                                                                                            |
| [`config/agents/`](config/agents)                                        | The agent skills lock, `review.csv`, and agent commands                                                                                                            |
| [`script/bootstrap-log.sh`](script/bootstrap-log.sh)                     | Logging wrapper sourced by `install` and `mise bootstrap` tasks; writes to `~/.local/state/dots/logs/`                                                             |
| [`test/`](test)                                                          | Verification suite: BDD features (`test/features/`) and Bun integration specs (`test/integration/`)                                                                |
| [`mise.toml`](mise.toml)                                                 | Repo tasks: `build`, `test`, `test:specs`, `start`, `setup:*`, `zsh:*`, `skills:*`                                                                                 |

## Day to day

### Check the state

```sh
mise bootstrap status            # every part: packages, files, dotfiles, tools, login shell
mise bootstrap status --missing  # same, but exits 1 when anything differs from the config
mise bootstrap plan              # what applying would change
brew bundle check --verbose        # packages: what the Brewfile wants but is missing
mise outdated                    # mise tools with a newer version
mise dot status                  # secrets history: tracked files, unsaved changes, last push
```

### Find, add and remove packages

```sh
brew search <text>                   # find a formula or cask
brew info <name>                     # show one
brew bundle add <name> [--cask]      # declare it in the Brewfile (then: brew bundle install)
brew bundle remove <name> [--cask]   # remove it from the Brewfile (then: brew bundle cleanup --force)
brew bundle install                  # install everything the Brewfile declares that is missing
```

`brew bundle add` appends to the end of the file, below `return unless desktop`, so a new package is
desktop-only; move its line up only if containers need it. Or edit
[`config/homebrew/Brewfile`](config/homebrew/Brewfile) by hand:

```ruby
brew "ripgrep"                       # above `return unless desktop`: containers too
brew "gnu-sed" if OS.mac?            # macOS only
cask "ghostty" if OS.mac?            # an app
tap "oven-sh/bun", "https://github.com/oven-sh/homebrew-bun.git"
uv "pynvim"                          # a Python tool
flatpak "dev.zed.Zed" if OS.linux?   # a Linux app (Flathub)
```

### Update

```sh
brew update && brew upgrade  # upgrade every package
brew bundle cleanup          # list installed packages the Brewfile does not declare (--force removes them)
mise upgrade                 # upgrade mise itself and repo task tools
mise bootstrap -E <profile>  # re-apply after editing the config
```

### Secrets

`~/.config/ssh` and `~/.config/gnupg` are tracked, encrypted, in the private `dots-history` repo. Other secrets
live in this repo, SOPS-encrypted on commit (`.sops.yaml`, `.gitattributes`): `config/.env`, `config/ssh/keys`,
`config/gopass/age`, `config/wakatime/.wakatime.cfg`; commit them like any file. After changing ssh or gnupg:

```sh
mise dot save   # record a checkpoint
mise dot sync   # push it
```

On another machine: `mise dot sync && mise dot pull`.

### Back up

```sh
mise run backup                                   # the allowlist in config/restic/backup.toml → restic, then check
mise run backup:restore -- --include Work --dry-run
mise run reinstall:audit                          # before a wipe: what would be lost
```

The policy is [`config/restic/backup.toml`](config/restic/backup.toml); the full playbook is
[`docs/REINSTALL.md`](docs/REINSTALL.md).

### Agent skills

Skills come from [`config/agents/skill-lock.json`](config/agents/skill-lock.json), the `skills` CLI's own lock
(both paths it reads link there), so `skills add <repo> -g` and `skills update` show up as a git diff: commit it.
The bootstrap restores missing skills in parallel in the background, logging to
`~/.local/state/dots/skills-restore.log` and sending an OS notification upon completion. Set
`DOTS_SKILLS_FOREGROUND=1` to wait for them. Logs: `~/.local/state/dots/logs/latest.log`.

```sh
mise run skills:restore   # install every locked skill that is missing (foreground run)
mise run skills:audit     # list skills whose source is not confirmed in config/agents/review.csv
```

## Configurations

| Area                                | Config                                                                                             |
| ----------------------------------- | -------------------------------------------------------------------------------------------------- |
| Zsh (shell, functions, plugins)     | [`config/zsh`](config/zsh/README.md)                                                               |
| Neovim                              | [`config/nvim`](config/nvim/README.md)                                                             |
| Git                                 | [`config/git`](config/git/README.md)                                                               |
| Git hooks (hk)                      | [`config/hk`](config/hk/README.md)                                                                 |
| SSH                                 | [`config/ssh`](config/ssh/README.md)                                                               |
| SOPS (encrypted files in this repo) | [`config/sops`](config/sops/README.md)                                                             |
| Terminal helpers (`~/.local/bin`)   | [`config/bin`](config/bin/README.md)                                                               |
| Helix                               | [`config/helix`](config/helix/README.md)                                                           |
| bat                                 | [`config/bat`](config/bat/README.md)                                                               |
| Ghostty                             | [`config/ghostty`](config/ghostty)                                                                 |
| Window management (macOS)           | [`config/dinky`](config/dinky), [`config/yabai`](config/yabai)                                     |
| mise                                | [`config/mise`](config/mise)                                                                       |
| Agent skills and commands           | [`config/agents`](config/agents)                                                                   |

## Playbooks

| Playbook                                               | Where                                                                                             |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Test `install` in a container                          | [Docker guide](docs/DOCKER.md#testing-install-in-a-container)                                      |
| Build, run and structure-test the Docker images        | [Docker guide](docs/DOCKER.md)                                                                    |
| Run the tests (BDD and integration specs)              | [Testing guide](docs/TESTING.md#verification-gates)                                               |
| Verify and benchmark zsh startup                       | [Testing guide](docs/TESTING.md#zsh-startup)                                                      |
| Prepare a reinstall (backups, new-Mac runbook)         | [Reinstall guide](docs/REINSTALL.md)                                                              |
| Reinstall a Mac                                        | [Reinstall guide](docs/REINSTALL.md)                                                              |
| Set or check macOS preferences                         | [macOS guide](docs/MACOS.md)                                                                      |
| Tile windows with the fn keys                          | [Tiling guide](docs/TILING.md)                                                                    |
| Work on this repo with an agent                        | [AGENTS.md](AGENTS.md)                                                                            |

## Gotchas

- **`mise x` tries to install every missing global tool** and fails: prefix it with
  `MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0`.
- **`mise dot sync` hangs:** GitHub HTTPS signs in through `gh`; check `gh auth status`.
- **A new shell lacks the profile's tools:** they load through `config/mise/miserc.local.toml`, which `install`
  writes; re-run `install` or create it with `env = ["<profile>"]`.
- **`brew bundle cleanup` only lists** what it would remove; add `--force` to remove it.
- **A package failed during `mise bootstrap`:** the core group (the shell set) stops the bootstrap; any other
  Brewfile entry only warns, and the bootstrap finishes. The names are in
  `~/.local/state/dots/brew-bundle.failed`, the output in `brew-bundle.log` beside it; fix the entry (an
  architecture gate such as `if OS.linux? && Hardware::CPU.intel?`, or remove it), then `brew bundle install`.
  With `CI` or `DOTS_STRICT` set, any failure stops the bootstrap.
- **`skills add` and `skills update` write the committed lock** through its link: review the diff.
- **A skill deleted upstream cannot be restored:** the lock records no commit; keep a backup.
- **Encrypted files (`config/.env`) look like gibberish in git:** run `mise run setup:git:filters`.
- **A bootstrap failed:** read `~/.local/state/dots/logs/latest.log`.

## Repository layout

| Path                                         | Holds                                                                |
| -------------------------------------------- | -------------------------------------------------------------------- |
| [`install`](install)                         | The one-liner's bootstrap script                                     |
| [`config/`](config)                          | Everything linked into `~/.config`, plus the mise config             |
| [`distros/`](distros)                        | Debian and Ubuntu Dockerfiles and structure tests                    |
| [`docs/`](docs)                              | Canonical documentation and agent specs/plans                        |
| [`script/`](script)                          | Repo scripts: SOPS filters, zsh checks, backup, logging, skills      |
| [`test/`](test)                              | BDD living documentation and Bun integration specs                   |
| [`mise.toml`](mise.toml), [`hk.pkl`](hk.pkl) | Repo tasks and git hooks                                             |

## Docs

- [`README.md`](README.md) — What dots is, installation, day-to-day usage, playbooks, gotchas, layout, docs index.
- [`AGENTS.md`](AGENTS.md) — Agent entry point: repository layout, workflow, quality gates, hard rules, and companion skills.
- [`docs/TESTING.md`](docs/TESTING.md) — Verification gates, Bun integration spec architecture, BDD and Gherkin rules, and Definition of Done.
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) — Commit conventions, code style standards, and mise task conventions.
- [`docs/DOCKER.md`](docs/DOCKER.md) — Container images, CST testing, and GitHub Actions CI pipelines.
- [`docs/REINSTALL.md`](docs/REINSTALL.md) — Backup runbook and clean-machine reinstall procedure.
- [`docs/MACOS.md`](docs/MACOS.md) — macOS preferences applied by the bootstrap, drift checks, undo, and the manual checklist.
- [`docs/TILING.md`](docs/TILING.md) — yabai tiling, the ten spaces, the fn keys (Karabiner), setup and troubleshooting.
- [`docs/GLOSSARY.md`](docs/GLOSSARY.md) — Common terms and domain glossary.

## License

[MIT](LICENSE)
