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
| `desktop`      | A real machine       | Nothing; moves an existing `~/.bashrc`, `~/.profile`, `~/.zshenv`, `~/.ssh`, `~/.gnupg` aside first |
| `container`    | Docker images        | The login shell; replaces the image's dotfiles                                                      |
| `devcontainer` | Fast container tests | The login shell, system packages (apt, Homebrew), the Neovim setup and agent skills                 |

Later, to apply config changes: `mise bootstrap -E <profile>`.

## How it works

`install` prepares the machine and hands over to `mise bootstrap`. mise reads `~/.config/mise`, which links to
`config/mise/` in this repo, so editing a file there and re-running `mise bootstrap` applies it.

| File                                                                     | Holds                                                                                                                                                              |
| ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [`config/mise/config.toml`](config/mise/config.toml)                     | `[tools]` mise installs itself (`npm:`, `pipx:`, `aqua:`), settings, the encrypted history (`[dotfiles]` track entries), and the `up`, `brew:*` and `backup` tasks |
| [`config/mise/conf.d/packages.toml`](config/mise/conf.d/packages.toml)   | `[bootstrap.packages]`: Homebrew formulae and casks, apt and flatpak packages, with `os` and `env` gates                                                           |
| [`config/mise/conf.d/bootstrap.toml`](config/mise/conf.d/bootstrap.toml) | Directories, system files, the login shell, and the `bootstrap` task (git filters, hooks, gopass store, oMLX models, agent skills, Neovim)                         |
| [`config/mise/conf.d/dotfiles.toml`](config/mise/conf.d/dotfiles.toml)   | Links from `~/.config/*` into this repo                                                                                                                            |
| `config/mise/config.<profile>.toml`                                      | Per-profile overrides ([`devcontainer`](config/mise/config.devcontainer.toml): the minimal tool set)                                                               |
| [`config/agents/`](config/agents)                                        | The agent skills lock, `review.csv`, and agent commands                                                                                                            |
| [`mise.toml`](mise.toml)                                                 | Repo tasks: `build`, `test`, `start`, `setup:*`, `zsh:*`, `skills:*`                                                                                               |

## Day to day

### Check the state

```sh
mise bootstrap status            # every part: packages, files, dotfiles, tools, login shell
mise bootstrap status --missing  # same, but exits 1 when anything differs from the config
mise bootstrap plan              # what applying would change
mise bootstrap packages status   # packages only
mise outdated                    # mise tools with a newer version
mise dot status                  # secrets history: tracked files, unsaved changes, last push
```

## Managing packages

```sh
mise bootstrap packages apply       # Installs missing packages only
mise bootstrap -E desktop           # Applies everything of the desktop profile: packages, links, directories, login shell, the bootstrap task
mise run up                         # Upgrade every package and prune undeclared ones
```

### Find, add and remove packages

```sh
mise run brew:search <text>          # search Homebrew formulae and casks
mise run brew:info <name> [--cask]   # show one
mise run brew:add <name> [--cask]    # declare it in conf.d/packages.toml and install it
mise run brew:rm <name> [--cask]     # remove it from conf.d/packages.toml and uninstall it
```

Or edit [`conf.d/packages.toml`](config/mise/conf.d/packages.toml) by hand, then run `mise bootstrap -E <profile>`:

```toml
[bootstrap.packages]
"brew:ripgrep" = "latest"                       # everywhere
"brew:gnu-sed" = { os = "macos" }               # macOS only
"brew:act" = { env = "desktop" }                # desktop profile only
"brew-cask:ghostty" = { os = "macos" }          # a cask
"brew:oven-sh/bun/bun" = { os = "macos" }       # from a tap declared in [bootstrap.brew.taps]
"apt:build-essential" = { os = "linux" }        # Debian/Ubuntu package
"flatpak:dev.zed.Zed" = { env = "desktop" }     # Linux desktop app (Flathub)
```

mise installs Homebrew bottles and casks itself, without `brew`. Tools mise can install directly (`npm:`,
`pipx:`, `aqua:`) go in `[tools]` of [`config.toml`](config/mise/config.toml) instead.

### Update

```sh
mise run up                  # upgrade every package, then prune undeclared ones (asks first)
mise upgrade                 # upgrade mise [tools]
mise bootstrap -E <profile>  # re-apply after editing the config
```

### Secrets

`~/.config/ssh`, `~/.config/gnupg` and `~/.config/gopass` are tracked, encrypted, in the private `dots-history`
repo. After changing one:

```sh
mise dot save   # record a checkpoint
mise dot sync   # push it
```

On another machine: `mise dot sync && mise dot pull`.

### Agent skills

Skills come from [`config/agents/skill-lock.json`](config/agents/skill-lock.json), the `skills` CLI's own lock
(both paths it reads link there), so `skills add <repo> -g` and `skills update` show up as a git diff: commit it.

```sh
mise run skills:restore   # install every locked skill that is missing (the bootstrap task runs this)
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
| Window management (macOS)           | [`config/amethyst`](config/amethyst), [`config/yabai`](config/yabai), [`config/skhd`](config/skhd) |
| mise                                | [`config/mise`](config/mise)                                                                       |
| Agent skills and commands           | [`config/agents`](config/agents)                                                                   |

## Playbooks

| Playbook                                               | Where                                                                                             |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| Test `install` in a container (`devcontainer` profile) | [Docker guide](assets/guides/DOCKER_GUIDE.md#testing-install-in-a-container-devcontainer-profile) |
| Build, run and structure-test the Docker images        | [Docker guide](assets/guides/DOCKER_GUIDE.md)                                                     |
| Run the tests (BDD and integration specs)              | [Testing guide](assets/guides/TESTING_GUIDE.md#verification-gates)                                |
| Verify and benchmark zsh startup                       | [Testing guide](assets/guides/TESTING_GUIDE.md#zsh-startup)                                       |
| Prepare a reinstall (backups, new-Mac runbook)         | [mise-bootstrap design §6](assets/specs/mise-bootstrap/design.md#6-new-mac-runbook)               |
| Work on this repo with an agent                        | [AGENTS.md](AGENTS.md)                                                                            |

## Gotchas

- **`mise x` tries to install every missing global tool** and fails: prefix it with
  `MISE_AUTO_INSTALL=0 MISE_EXEC_AUTO_INSTALL=0`.
- **`mise dot sync` hangs:** GitHub HTTPS signs in through `gh`; check `gh auth status`.
- **A new shell lacks the profile's tools:** they load through `config/mise/miserc.local.toml`, which `install`
  writes; re-run `install` or create it with `env = ["<profile>"]`.
- **`brew:` packages are not on PATH in a script:** they live in the Homebrew prefix (`/opt/homebrew/bin`,
  `/home/linuxbrew/.linuxbrew/bin`), which only an interactive shell adds.
- **`skills add` and `skills update` write the committed lock** through its link: review the diff.
- **A skill deleted upstream cannot be restored:** the lock records no commit; keep a backup.
- **Encrypted files (`config/.env`) look like gibberish in git:** run `mise run setup:git:filters`.

## Repository layout

| Path                                         |                                                                      |
| -------------------------------------------- | -------------------------------------------------------------------- |
| [`install`](install)                         | The one-liner's script                                               |
| [`config/`](config)                          | Everything linked into `~/.config`, plus the mise config             |
| [`assets/`](assets)                          | Specs (`assets/specs/`), guides (`assets/guides/`), tests            |
| [`distros/`](distros)                        | Debian and Ubuntu Dockerfiles and structure tests                    |
| [`script/`](script)                          | Repo scripts: SOPS filters, zsh checks, the skills audit and restore |
| [`mise.toml`](mise.toml), [`hk.pkl`](hk.pkl) | Repo tasks and git hooks                                             |

## License

[MIT](LICENSE)
