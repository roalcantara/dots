# dots

[![Preview](https://github.com/roalcantara/dots/actions/workflows/preview.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/preview.yml)
[![Release](https://github.com/roalcantara/dots/actions/workflows/release.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/release.yml)
[![Publish](https://github.com/roalcantara/dots/actions/workflows/publish.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/publish.yml)

An opinionated [DotFiles][10] repository. Ready to Engage!

<!-- markdownlint-disable MD013 -->

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## Overview

**Dots** is a modular, cross-platform dotfiles configuration and automated development environment designed for macOS (Darwin), Linux (Debian, Ubuntu), and DevContainers.

### Key Features

- **Automated Bootstrap:** One-liner setup script configuring shell, user permissions, tools, and dotfile symlinks.
- **Shell & Prompt:** Fast, modern Zsh environment powered by [Zimfw][19] and the [Starship][25] prompt.
- **Composable CLI Suite:** A comprehensive library of standalone, `#USAGE`-documented terminal helpers in `config/bin/`.
- **Declarative Package Management:** Unified runtime management with [Mise][6], reproducible system packages via [Flox][16], and declarative macOS package management with [Homebrew Bundle][5].
- **Editor Configuration:** Fast, extensible [Neovim][26] setup powered by [LazyVim][27].
- **High-Performance Git Hooks:** Fast Rust-native git hooks via [hk][7] enforcing [Conventional Commits][9] and multi-linter verification.
- **Living Documentation & Testing:** Spec-Driven Development (SDD) planning artifacts, BDD living documentation with Gherkin/Cucumber, and Bun subprocess integration specs in `assets/`.
- **DevContainer & Docker Ready:** Multi-arch container builds and Container Structure Tests for Debian and Ubuntu environments.

---

## Install

On a fresh macOS or Debian/Ubuntu machine (macOS: run `xcode-select --install` first for `git`):

```sh
curl -fsSL https://raw.githubusercontent.com/roalcantara/dots/main/install | bash
```

`install` installs mise, clones this repo into `~/.local/share/dots`, asks you to paste the age key (hidden input;
keep it in your password manager), links `~/.config/mise`, signs `gh` in to GitHub (a browser device flow) and runs
[`mise bootstrap`](https://mise.jdx.dev/bootstrap.html) twice:

1. `mise bootstrap --adopt` restores the encrypted secrets from the private `dots-history` repository:
   `~/.config/ssh`, `~/.config/gnupg` and `~/.config/gh/hosts.yml`.
2. `mise bootstrap -E desktop` applies `config/mise/`: packages, links, directories, login shell, the setup task.

It creates no user and sets no timezone: the machine's own setup does that. A second run changes nothing.

| Variable | Default | |
| --- | --- | --- |
| `DOTS_BRANCH` | `main` | Branch to clone (to try a branch, fetch `install` from it too) |
| `DOTS_REPO` | `https://github.com/roalcantara/dots.git` | Repository to clone |
| `DOTS_HISTORY` | `https://github.com/roalcantara/dots-history.git` | Encrypted history to restore |
| `DOTS_PROFILE` | `desktop` | `container` skips the login shell and replaces a base image's dotfiles |
| `DOTS_AGE_KEY` | — | The key itself, for tests; otherwise it is prompted |

Docker images do not use `install` and get no secrets; see `assets/guides/DOCKER_GUIDE.md`. Later runs:
`mise bootstrap -E desktop`.

### OVEREVIEW

- **Features**

  - ✅ Installation script to setup a development environment
  - ✅ Ready to be used in [DevContainers][15]
  - ✅ Uses whatever shell the install script configured

- **DevContainer**

  - ✅ Provides essential environment and tools to start developing
  - ✅ Installs essential tools and dependencies via [Mise][6]

- **Tooling**

    | **Manager** | **Package** | **Description**                                                        |
    | :---------: | ----------- | ---------------------------------------------------------------------- |
    |   DISTRO    | Ruby        | Powerful, clean, object-oriented scripting language                    |
    |   DISTRO    | Git         | Distributed version control system                                     |
    |   DISTRO    | ZSH         | UNIX shell (command interpreter)                                       |
    |    MISE     | Bat         | cat(1)'s clone with syntax highlighting and Git integration            |
    |    MISE     | Delta       | Syntax-highlighter and pager for git and diff output                   |
    |    MISE     | Eza         | Modern, maintained replacement for ls                                  |
    |    MISE     | Fd          | Simple, fast and user-friendly alternative to find                     |
    |    MISE     | Fzf         | Command-line fuzzy finder written in Go                                |
    |    MISE     | Gh          | GitHub command-line tool                                               |
    |    MISE     | Gum         | Tool for glamorous shell scripts                                       |
    |    MISE     | hk          | High-performance Rust-native git hook manager                          |
    |    MISE     | Node        | JavaScript runtime built on Chrome's V8 JavaScript engine              |
    |    MISE     | Npm         | Package manager for JavaScript                                         |
    |    MISE     | Npx         | Execute JavaScript packages                                            |
    |    MISE     | Nvim        | Highly configurable text editor                                        |
    |    MISE     | Python3     | A programming language                                                 |
    |    MISE     | Rg          | A tool for searching text with regex                                   |
    |    MISE     | Starship    | Minimal, blazing-fast, and extremely customizable prompt for any shell |
    |    MISE     | Usage       | Display command usage statistics                                       |
    |    MISE     | Watchexec   | Execute commands when files change                                     |
    |    MISE     | Zoxide      | Smarter cd command for your terminal                                   |

## Homebrew Configuration

We use `mise run bundle` to manage Homebrew dependencies. See [Homebrew Recipes](assets/guides/homebrew-recipes.md) for detailed configuration recipes and usage.

### DEPENDENCIES

- [Git][5]
- [Mise][6]
- [hk][7]
- [Docker][11]

## USAGE

### Git Hooks

This project uses [hk][7] to manage and run git hooks. Hooks are configured in `hk.pkl` at the root and are installed automatically by the `install` script.

To install or update hooks manually:

```sh
# Enter homebrew config directory or use mise -C config/homebrew:
cd config/homebrew

# Install and upgrade all dependencies from Brewfile:
mise run bundle install

# Check whether local installation matches declared state:
mise run bundle check

# Update Homebrew, upgrade packages, and reconcile dependencies:
mise run bundle update

# Clean up unneeded dependencies and run brew doctor:
mise run bundle cleanup

# Export currently installed packages into a Brewfile:
mise run bundle dump

# Add or remove dependencies from the Brewfile:
mise run bundle add formulae ripgrep
mise run bundle add cask ghostty
mise run bundle remove cask firefox
```

For recipes and syntax conventions, see the [Homebrew Recipes guide](assets/guides/homebrew-recipes.md) and [config/homebrew/README.md](config/homebrew/README.md).

---

## Documentation & Verification

Planning artifacts, living documentation, and automated test suites live under [`assets/`](assets/README.md).

```txt
assets/
├── guides/          Canonical architecture guides and glossary
├── specs/           SDD planning artifacts (requirements.md, design.md, tasks.md)
├── features/        BDD living documentation (Gherkin feature files)
└── integration/     Bun subprocess and script integration specs
```

| Layer           | Path                                         | Purpose                                                   | Verification Gate                          |
| --------------- | -------------------------------------------- | --------------------------------------------------------- | ------------------------------------------ |
| **Guides**      | [`assets/guides/`](assets/guides/)           | Best practices, glossary, code style, CI, Docker, testing | [GLOSSARY.md](assets/guides/GLOSSARY.md)   |
| **Specs**       | [`assets/specs/`](assets/specs/)             | Spec-Driven Development (SDD) feature contracts           | `requirements.md`, `design.md`, `tasks.md` |
| **BDD**         | [`assets/features/`](assets/features/)       | Gherkin living documentation across domains               | `mise run -C assets bdd run`               |
| **Integration** | [`assets/integration/`](assets/integration/) | Subprocess and script verification with `bun:test`        | `mise run -C assets integration bin all`   |

### Running Verification Tests

```sh
# Run the full test suite (BDD features + integration specs):
mise run -C assets test all

# Run bin domain tests only:
mise run -C assets test bin

# Run BDD linting and execution:
mise run -C assets bdd lint
mise run -C assets bdd run --domain bin

# Run specific integration spec:
mise run -C assets integration bin xc-usage
```

Refer to the [Testing Guide](assets/guides/TESTING_GUIDE.md) and [BDD Guide](assets/guides/BDD_GUIDE.md) for full details.

---

## Agent Workflow

When contributing or implementing features with AI coding agents, follow the standard Spec-Driven Development (SDD) process:

1. **Planning Phase:**
   - Read [`assets/guides/GLOSSARY.md`](assets/guides/GLOSSARY.md) and relevant guides.
   - Author SDD documents (`requirements.md`, `design.md`, `tasks.md`) under `assets/specs/<feature-slug>/`.
   - Never write specs to `docs/superpowers/` — redirect to `assets/specs/<feature-slug>/`.
   - Halt for review and create `HANDOFF.md` once specifications are approved.

2. **Implementation Phase:**
   - Execute tasks step-by-step from `assets/specs/<feature-slug>/tasks.md`.
   - Ensure all quality gates (`mise run -C assets test all`, linters, type checks) pass with zero warnings and errors.
   - Commit changes atomically using [Conventional Commits](assets/guides/GIT_COMMITS_GUIDE.md).

---

## Docker & DevContainers

The repository includes Dockerfiles under `distros/` for building and testing container environments on Debian and Ubuntu.

### Building Docker Images

```sh
# Build default Debian image:
mise run build

# Build Ubuntu image:
mise run build --distro ubuntu

# Build without cache for local testing:
mise run build --nocache --local --tag dev

# Multi-arch build:
mise run build --platform amd64 --tag latest
```

### Running Dev Containers

```sh
# Start interactive shell in base Debian container:
mise run start

# Start interactive shell in built custom image:
mise run start --tag dev --user vscode

# Start Ubuntu container on amd64:
mise run start --distro ubuntu --platform amd64 --tag latest
```

### Container Testing (CST)

Verify container image structure using [Container Structure Tests (CST)][12]:

```sh
# Run CST against the default build image:
mise run test

# Run CST with custom tag and platform:
mise run test --tag latest --platform arm64
```

---

### Terminal Helpers (`config/bin`)

Scripts live in `config/bin/` and are symlinked to `~/.local/bin` during installation. Helper tools adopt modern `#USAGE` CLI headers (or docopt `##?` headers with `xc-usage`) for automated argument parsing and formatted `--help` output.

| Command                                                         | Purpose                                                                      | Example                            |
| --------------------------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------- |
| [`xc-usage`](config/bin/xc-usage)                               | Extract and print `##?` help from bin scripts and Zsh functions              | `xc-usage xc-git`                  |
| [`xc-md`](config/bin/xc-md)                                     | Markdown renderer from stdin with graceful fallback (glow → bat → plain)     | `xc-usage gen --md`                |
| [`xc-git`](config/bin/xc-git)                                   | Unified Git workflow helper (branch preview, fixup suggestion, log fzf)      | `xc-git fixup-suggest --dry-run .` |
| [`xc-fabric`](config/bin/xc-fabric)                             | Interactive [Fabric][20] AI pattern runner with fzf and gum                  | `xc-fabric ls --raw`               |
| [`xc-skills`](config/bin/xc-skills)                             | Sync or collect skill symlinks across AI agent config directories            | `xc-skills sync --dry-run`         |
| [`xc-puts`](config/bin/xc-puts)                                 | Formatted, colored console messages for scripts and installers               | `xc-puts --green "ready"`          |
| [`xc`](config/bin/xc)                                           | Interactive fzf launcher for all `xc-*` tools                                | `xc`                               |
| [`barrel`](config/bin/barrel)                                   | TypeScript and JavaScript barrel (`index.ts`/`index.js`) export generator    | `barrel ./src -r`                  |
| [`recase`](config/bin/recase)                                   | File and directory naming convention converter (snake, kebab, camel, pascal) | `recase MyFile.ts --kebab`         |
| [`toast`](config/bin/toast) / [`xc-toast`](config/bin/xc-toast) | Short-lived terminal toast notifications                                     | `toast "Build completed" 2`        |
| [`dots`](config/bin/dots)                                       | Dotfiles manager, runtime permissions, theme palette, and diagnostics        | `dots doctor`                      |
| [`osx`](config/bin/osx)                                         | macOS maintenance, system defaults, and services management CLI              | `osx clean`                        |
| [`gitx`](config/bin/gitx)                                       | Interactive Git rebase, history, and branch workflow dispatcher              | `gitx fzl`                         |
| [`xcz`](config/bin/xcz)                                         | Shell environment, path auditor, and system diagnostic utility               | `xcz env`                          |
| [`yw`](config/bin/yw)                                           | Interactive Yarn/NPM workspace package and script runner                     | `yw`                               |
| [`keyring`](config/bin/keyring)                                 | Agnostic macOS Keychain and Linux keyring secret manager                     | `keyring get api_key`              |
| [`psc`](config/bin/psc) / [`pss`](config/bin/pss)               | Gopass secret clipboard copier (`psc`) and secret revealer (`pss`)           | `psc github/token`                 |
| [`gen`](config/bin/gen)                                         | Zsh completion script generator from command `--help` outputs                | `gen mycmd`                        |

Detailed tool options and authoring conventions: [config/bin/README.md](config/bin/README.md).

## Benchmarks & Performance

Zsh startup performance is tracked and profiled to ensure sub-millisecond shell initialization:

| Date                | Command               | User  | System |  CPU  | Total | Comment                              | Source        |
| ------------------- | --------------------- | :---: | :----: | :---: | :---: | ------------------------------------ | ------------- |
| 2025-09-22 05:00:57 | `dots zsh --prof avg` | 782ms |  98ms  |  91%  | 964ms | Initial load with Gopass key loading | `~/.zprofile` |
| 2025-09-22 05:08:57 | `dots zsh --prof avg` | 41ms  |  22ms  |  91%  | 71ms  | Optimized without Gopass key load    | `~/.zprofile` |
| 2025-09-22 05:20:00 | `dots zsh --prof avg` | 40ms  |  20ms  |  91%  | 69ms  | Optimized environment file discovery | `~/.zshenv`   |
| 2025-09-22 06:00:00 | `dots zsh --prof avg` | 41ms  |  21ms  |  90%  | 68ms  | Fast direct environment loading      | `~/.zprofile` |

---

## Contributing

- Bug reports and pull requests are welcome on [GitHub][0].
- Follow [EditorConfig][3] formatting and [Code Style Guidelines](assets/guides/CODESTYLE_GUIDE.md).
- Follow the [Conventional Commits][9] format for all commit messages.
- All contributors must adhere to the [Contributor Covenant][2] Code of Conduct.

---

## License

The project is available as open source under the terms of the [MIT License](LICENSE).

---

## Acknowledgements

- [Standard Readme][4]
- [Conventional Commits][9]
- [Dotfiles][10]
- [hk Git Hook Manager][7]
- [Mise Development Environment Manager][6]
- [Flox Declarative Environments][16]
- [CST (Container Structure Tests)][12]
- [OCI Best Practices Image Annotations][13]
- [DevContainers Specification][15]
- [Starship Prompt][25]
- [LazyVim][27]

[0]: https://github.com/roalcantara/dots 'Dots dotfiles repository'
[1]: https://opensource.org/licenses/MIT 'Open Source Initiative'
[2]: https://contributor-covenant.org 'Contributor Covenant'
[3]: https://editorconfig.org 'EditorConfig'
[4]: https://github.com/RichardLitt/standard-readme 'Standard Readme'
[5]: https://docs.brew.sh/Manpage#bundle-subcommand 'Homebrew Bundle Subcommand'
[6]: https://mise.jdx.dev 'Mise: Dev tools, env vars, task runner'
[7]: https://hk.jdx.dev 'hk: High-performance Rust-native git hook manager'
[8]: https://github.com/dandavison/delta 'Delta: A syntax-highlighting pager for git, diff, and grep output'
[9]: https://conventionalcommits.org 'Conventional Commits'
[10]: https://dotfiles.github.io 'GitHub Dotfiles'
[11]: https://docker.com 'Docker'
[12]: https://github.com/GoogleContainerTools/container-structure-test 'Container Structure Test'
[13]: https://github.com/opencontainers/image-spec/blob/main/annotations.md 'OCI Best Practices Image Annotations'
[14]: https://docker.com/blog/multi-arch-build-and-images-the-simple-way 'Multi-arch build and images the simple way'
[15]: https://containers.dev 'DevContainers'
[16]: https://flox.dev 'Flox: Developer Environments'
[17]: https://jetify.com/devbox 'Devbox: Portable, Isolated Dev Environments'
[18]: https://devenv.sh 'Devenv: Fast, Declarative Developer Environments using Nix'
[19]: https://zimfw.sh 'Zim: Modular, customizable, and blazing fast Zsh framework'
[20]: https://github.com/danielmiessler/fabric 'Fabric: open-source framework for augmenting humans using AI'
[21]: https://github.com/junegunn/fzf 'fzf: command-line fuzzy finder'
[22]: https://github.com/charmbracelet/gum 'Gum: Tool for glamorous shell scripts'
[23]: https://github.com/charmbracelet/glow 'Glow: Terminal based markdown reader'
[24]: https://github.com/sharkdp/bat 'bat: A cat clone with wings'
[25]: https://starship.rs 'Starship: Cross-Shell Prompt'
[26]: https://neovim.io 'Neovim: Vim-fork focused on extensibility and usability'
[27]: https://lazyvim.org 'LazyVim: A Neovim setup powered by lazy.nvim'
