# dots

[![Preview](https://github.com/roalcantara/dots/actions/workflows/preview.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/preview.yml)
[![Release](https://github.com/roalcantara/dots/actions/workflows/release.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/release.yml)
[![Publish](https://github.com/roalcantara/dots/actions/workflows/publish.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/publish.yml)

An opinionated [DotFiles][10]. Ready to Engage!

<!-- markdownlint-disable MD013 -->
[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## INSTALL

At the moment, the `install` script is only handles `debian` and `ubuntu` distros.

- One-liner Installation script `roalcantara:wheel` by default

    ```sh
    wget -qO- "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash
    ```

- One-liner Installation script with custom user and group

    ```sh
    wget -qO- "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash -s -- -u "vscode" -g "vscode"
    ```

- Normal Installation `roalcantara:wheel` by default

    ```sh
    git clone https://github.com/roalcantara/dots ~/.local/share/dots && ~/.local/share/dots/install
    ```

- Normal Installation with custom user and group

    ```sh
    git clone https://github.com/roalcantara/dots ~/.local/share/dots && ~/.local/share/dots/install -u "vscode" -g "vscode"
    ```

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
mise run setup:hooks
```

Once installed, the hooks will validate your commit messages against Conventional Commits rules on `commit-msg` and automatically run linters (`shellcheck`, `shfmt`, `markdownlint`, `hadolint`, `yamllint`, `taplo`) on staged files during `pre-commit`.

You can also run hook commands manually:

- `hk check` (or `mise x hk -- hk check`): Standalone manual check to lint staged files.
- `hk fix` (or `mise x hk -- hk fix`): Auto-format and fix staged files before committing.

### Terminal helpers (config/bin)

Scripts live in `config/bin/` and are symlinked to `~/.local/bin` (prefix `xc-` avoids collisions with system CLIs). Help is [docopt](http://docopt.org/)-shaped: run `xc-<tool> -h` or `xc-<tool> <subcommand> -h`.

| Command                             | What it does                                                                                                         |
| ----------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| [`xc-usage`](config/bin/xc-usage)   | Extract and print `##?` help from bin scripts (`guard`, `print`, `validate`)                                         |
| [`xc-puts`](config/bin/xc-puts)     | Colored and prefixed messages for scripts and installers (replaces the Zsh `puts` function)                          |
| [`xc-toast`](config/bin/xc-toast)   | Short-lived terminal toasts: `message [duration] [type]` (replaces Zsh `toast`)                                      |
| [`xc-git`](config/bin/xc-git)       | Git workflow helpers (see subcommands below)                                                                         |
| [`xc-fabric`](config/bin/xc-fabric) | Interactive [Fabric](https://github.com/danielmiessler/fabric) pattern runner with fzf/gum                           |
| [`xc-skills`](config/bin/xc-skills) | Sync or collect skill symlinks across AI agent config directories                                                    |
| `xc`                                | Interactive fzf launcher for other `xc-*` tools ([spec](assets/specs/xc-launcher/design.md); install when available) |

**`xc-git` subcommands:**

| Subcommand                        | What it does                                                         |
| --------------------------------- | -------------------------------------------------------------------- |
| `branch-preview <branch>`         | Branch tip, history, and diff preview (for `git fzb` / `gitx fzb`)   |
| `fixup-suggest [opts] [-- paths]` | Suggest a fixup target commit or open an editor for a new commit     |
| `log-fzf [action]`                | Interactive `git log` with gitx-style actions (`git lol`, `git fzl`) |

```sh
xc-git -h
xc-git fixup-suggest --dry-run .
git add file && git fix "$(xc-git fixup-suggest -q -- file)"
git lol                    # → gitx → xc-git log-fzf
xc-puts --green "ready"
xc-fabric ls --raw
xc-skills sync --dry-run
```

Install symlinks, dependencies, and authoring rules: [config/bin/README.md](config/bin/README.md).

## Documentation and verification

Planning docs, living documentation, and script verification live under
[`assets/`](assets/README.md). This repository is not a Node application; the
root has no `package.json`.

| Path                                         | Purpose                                                   |
| -------------------------------------------- | --------------------------------------------------------- |
| [`assets/guides/`](assets/guides/)           | Canonical best practices and glossary                     |
| [`assets/specs/`](assets/specs/)             | SDD planning — `requirements.md`, `design.md`, `tasks.md` |
| [`assets/features/`](assets/features/)       | BDD living documentation (Gherkin), all domains           |
| [`assets/integration/`](assets/integration/) | Subprocess and script verification                        |

Verification dependencies are declared in [`assets/mise.toml`](assets/mise.toml)
and/or [`assets/package.json`](assets/package.json): mise for CLI tools (for
example `bun`, `node`), npm `devDependencies` for Cucumber and TypeScript
packages. Neovim busted specs remain under [`config/nvim/specs/`](config/nvim/specs/).

```sh
mise run -C assets test all   # full verification (from repo root)
mise run -C assets test bin   # bin domain: BDD + integration
```

Guides: [`assets/guides/GLOSSARY.md`](assets/guides/GLOSSARY.md) first, then
[`BDD_GUIDE.md`](assets/guides/BDD_GUIDE.md) for verification layers.
Layout and migration spec:
[`assets/specs/project-structure/design.md`](assets/specs/project-structure/design.md).

## Agent workflow

Use this workflow for agent-driven features unless a prompt explicitly overrides
it.

**Planning**

1. Read [`assets/guides/GLOSSARY.md`](assets/guides/GLOSSARY.md),
   [`assets/guides/BDD_GUIDE.md`](assets/guides/BDD_GUIDE.md), and relevant guides.
2. Use `spec-driven-development` (or `sdd`) to author SDD files under
   `assets/specs/<feature-slug>/`.
3. Do not write specs to `.superpowers/` or `docs/superpowers/`.
4. Stop after `requirements.md`, `design.md`, and `tasks.md` are approved.
5. Write or refresh `HANDOFF.md` for the implementation agent.

Default: **do not implement** in the planning session.

**Implementation**

1. Read `assets/specs/<feature-slug>/tasks.md` and `HANDOFF.md`.
2. Use `subagent-driven-development` per task unless the prompt requests inline work.
3. Complete one task group (`## Task N:`) at a time; run all gates with zero
   errors and warnings.
4. Mark task checkboxes complete only after gates pass.
5. Create one [conventional commit](assets/guides/GIT_COMMITS_GUIDE.md) per
   completed task group.

**Verification layers**

| Layer       | Path                  | Typical gates (from repo root)                          |
| ----------- | --------------------- | ------------------------------------------------------- |
| BDD         | `assets/features/`    | `mise run -C assets bdd lint`, `bdd dry-run`, `bdd run` |
| Integration | `assets/integration/` | `mise run -C assets integration bin all`                |
| Domain      | —                     | `mise run -C assets test bin`                           |
| Full        | —                     | `mise run -C assets test all`                           |

Run verification with `mise run -C assets …` from the repository root (root
`test` is Docker CST). Inside `assets/`, omit `-C assets`.

### BUILDING

At the moment, the `build` task is only available for the `debian` and `ubuntu` distros.

1. Basic

    ```sh
        mise run build
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian \
        #   --file=distros/debian/Dockerfile --target=remote .
        # ==> dots:debian

        mise run build --distro=ubuntu
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:ubuntu \
        #   --file=distros/ubuntu/Dockerfile --target=remote .
        # ==> dots:ubuntu

        mise run build --tag testing
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian-testing \
        #   --file=distros/debian/Dockerfile --target=remote .
        # ==> dots:debian-testing

        mise run build --nocache --tag preview
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian-preview \
        #   --no-cache --file=distros/debian/Dockerfile --target=remote .
        # ==> dots:debian-preview

        mise run build --tag latest --platform amd64
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/amd64 --tag=dots:debian-latest \
        #   --file=distros/debian/Dockerfile --target=remote .
        # ==> dots:debian-latest

        mise run build --local
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian \
        #   --file=distros/debian/Dockerfile --target=local .
        # ==> dots:debian

        mise run build --local --tag dev
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian-dev \
        #   --file=distros/debian/Dockerfile --target=local .
        # ==> dots:debian-dev

        mise run build --local --nocache --tag stag
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/arm64 --tag=dots:debian-stag \
        #   --no-cache --file=distros/debian/Dockerfile --target=local .
        # ==> dots:debian-stag

        mise run build --local --nocache --tag local --platform amd64
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --platform=linux/amd64 --tag=dots:debian-local \
        #   --no-cache --file=distros/debian/Dockerfile --target=local .
        # ==> dots:debian-local
    ```

2. Advanced

    ```sh
        mise run build --branch main --repo roalcantara/dotfiles --user root --group root --workdir /workspaces/foo --tag custom
        # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --build-arg=GITHUB_REPO=roalcantara/dotfiles \
        #   --build-arg=BRANCH=main --build-arg=USERNAME=root --build-arg=GROUPNAME=root --workdir=/workspaces/foo \
        #   --tag=dots:debian-custom --file=distros/debian/Dockerfile --target=remote .
    ```

#### RUNNING

At the moment, the `start` task is only available for the `debian` and `ubuntu` distros.

 ```sh
  mise run start
  # ==> docker run -it --rm --user=vscode --workdir=/workspaces/dots --entrypoint=zsh mcr.microsoft.com/devcontainers/base:debian

  mise run start --user root --workdir /workspaces/foo
  # ==> docker run -it --rm --user=root --workdir=/workspaces/foo --entrypoint=zsh mcr.microsoft.com/devcontainers/base:debian

  mise run start --tag dev
  # ==> docker run -it --rm --user=vscode --workdir=/workspaces/dots dots:debian-dev

  mise run start --platform amd64 --tag latest
  # ==> docker run -it --rm --user=vscode --workdir=/workspaces/dots dots:debian-latest

  mise run start --distro ubuntu --tag latest
  # ==> docker run -it --rm --user=vscode --workdir=/workspaces/dots dots:ubuntu-latest
```

### TESTING

1. Install [CST (Container Structure Tests)][12]

    ```sh
    brew install container-structure-test
    ```

2. Build and running the Container Structure Tests

    ```sh
        mise run build
        # ==> dots:debian
        mise run test
        # ==> container-structure-test test --image dots:debian --config distros/debian/container-structure-test.yml

        mise run build --tag stag
        # ==> dots:debian-stag
        mise run test --tag stag
        # ==> container-structure-test test --image dots:debian-stag --config distros/debian/container-structure-test.yml

        mise run build --tag testing --platform amd64
        # ==> dots:debian-testing
        mise run test --tag testing --platform amd64
        # ==> container-structure-test test --image dots:debian-testing --config distros/debian/container-structure-test.yml

        mise run build --tag local --platform amd64
        # ==> dots:debian-local
        mise run test --image dots:debian-local --config distros/debian/container-structure-test.yml
        # ==> container-structure-test test --image dots:debian-local --config distros/debian/container-structure-test.yml

        mise run build --distro ubuntu --tag latest
        # ==> dots:ubuntu-latest
        mise run test --distro ubuntu --tag latest
        # ==> container-structure-test test --image dots:ubuntu-latest --config distros/ubuntu/container-structure-test.yml
    ```

## REPORTS

| **DATE**            | **COMMAND**         | **USER** | **SYSTEM** | **CPU** | **TOTAL** | **COMMENT**                                                                                                                                                                   | **SOURCE**    |
| ------------------- | ------------------- | :------: | :--------: | :-----: | :-------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- |
| 2025-09-22 05:00:57 | dots zsh --prof avg |  782ms   |    98ms    |   91%   |   964ms   | WHEN LOADING KEYS FROM GOPASS                                                                                                                                                 | `~/.zprofile` |
| 2025-09-22 05:08:57 | dots zsh --prof avg |   41ms   |    22ms    |   91%   |   71ms    | NO LOADING KEYS FROM GOPASS                                                                                                                                                   | `~/.zprofile` |
| 2025-09-22 05:20:00 | dots zsh --prof avg |   40ms   |    20ms    |   91%   |   69ms    | WITHOUT `set -a; while IFS= read -r -d '' env_file; do source $env_file; done < <(find -L "$HOME/.config/xdg" -maxdepth 1 -name "*.env" -type f -print0 2>/dev/null); set +a` | `~/.zhenv`    |
| 2025-09-22 06:00:00 | dots zsh --prof avg |   41ms   |    21ms    |   90%   |   68ms    | WITH `set -a; source $HOME/.config/.env; set +a`                                                                                                                              | `~/.zprofile` |

## ACKNOWLEDGEMENTS

- [Standard Readme][4]
- [Conventional Commits][9]
- [Dotfiles][10]
- [CST (Container Structure Tests)][12]
- [OCI Best Practices Image Annotations][13]
- [Multi-arch build and images the simple way][14]
- [Flox: Manage all of your software and its dependencies, down to the smallest package][16]
- [Devbox: Portable, Isolated Dev Environments on any Machine][17]
- [Devenv: Fast, Declarative, Reproducible and Composable Developer Environments using Nix][18]

## CONTRIBUTING

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][3] rules.
- All contributors must follow the [Contributor Covenant][2] code of conduct.

## LICENSE

The project is available as open source under the terms of the [MIT][1] [License](LICENSE)

[0]: https://github.com/roalcantara/dots 'Yet another app'
[1]: https://opensource.org/licenses/MIT 'Open Source Initiative'
[2]: https://contributor-covenant.org 'A Code of Conduct for Open Source Communities'
[3]: https://editorconfig.org 'EditorConfig'
[4]: https://github.com/RichardLitt/standard-readme 'Standard Readme'
[5]: https://git-scm.com 'Distributed version control system'
[6]: https://mise.jdx.dev 'Manages dev tools like node, python, cmake, terraform, and hundreds more'
[7]: https://hk.jdx.dev 'High-performance Rust-native git hook manager'
[9]: https://conventionalcommits.org 'Conventional Commits'
[10]: https://dotfiles.github.io 'Your unofficial guide to dotfiles on GitHub'
[11]: https://docker.com 'Docker'
[12]: https://github.com/GoogleContainerTools/container-structure-test 'CST (Container Structure Tests): validate the structure of your container images'
[13]: https://github.com/opencontainers/image-spec/blob/main/annotations.md 'OCI Best Practices Image Annotations'
[14]: https://docker.com/blog/multi-arch-build-and-images-the-simple-way 'Multi-arch build and images the simple way'
[15]: https://containers.dev 'Open specification for enriching containers with development specific content and settings'
[16]: https://flox.dev 'The Flox tool - Manage all of your software and its dependencies, down to the smallest package'
[17]: https://jetify.com/devbox 'Devbox: Portable, Isolated Dev Environments on any Machine'
[18]: https://devenv.sh 'Devenv: Fast, Declarative, Reproducible and Composable Developer Environments using Nix'
