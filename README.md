# dots

[![Preview](https://github.com/roalcantara/dots/actions/workflows/preview.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/preview.yml)
[![Release](https://github.com/roalcantara/dots/actions/workflows/release.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/release.yml)
[![Publish](https://github.com/roalcantara/dots/actions/workflows/publish.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/publish.yml)

An opinionated [DotFiles][10]. Ready to Engage!

<!-- markdownlint-disable MD013 -->
[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## INSTALL

At the moment, the `install` script is only handles `debian` and `ubuntu` distros.

- One-liner Installation script

    ```sh
    # roalcantara:wheel by default
    curl -fsSL "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash

    # customizing user and group
    curl -fsSL "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash -s -- -u "vscode" -g "vscode"
    ```

- Normal Installation

    ```sh
    # Clone the repository and run the install script (roalcantara:wheel)
    git clone https://github.com/roalcantara/dots ~/.local/share/dots && ~/.local/share/dots/install

    # Clone the repository and run the install script with customization (vscode:vscode)
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
    |   DISTRO    | GitLint     | Git commit message linter                                              |
    |   DISTRO    | ZSH         | UNIX shell (command interpreter)                                       |
    |    MISE     | Bat         | cat(1)'s clone with syntax highlighting and Git integration            |
    |    MISE     | Delta       | Syntax-highlighter and pager for git and diff output                   |
    |    MISE     | Eza         | Modern, maintained replacement for ls                                  |
    |    MISE     | Fd          | Simple, fast and user-friendly alternative to find                     |
    |    MISE     | Fzf         | Command-line fuzzy finder written in Go                                |
    |    MISE     | Gh          | GitHub command-line tool                                               |
    |    MISE     | Gum         | Tool for glamorous shell scripts                                       |
    |    MISE     | Node        | JavaScript runtime built on Chrome's V8 JavaScript engine              |
    |    MISE     | Npm         | Package manager for JavaScript                                         |
    |    MISE     | Npx         | Execute JavaScript packages                                            |
    |    MISE     | Nvim        | Highly configurable text editor                                        |
    |    MISE     | Pre-Commit  | Manage multi-language pre-commit hooks                                 |
    |    MISE     | Python3     | A programming language                                                 |
    |    MISE     | Rg          | A tool for searching text with regex                                   |
    |    MISE     | Starship    | Minimal, blazing-fast, and extremely customizable prompt for any shell |
    |    MISE     | Usage       | Display command usage statistics                                       |
    |    MISE     | Watchexec   | Execute commands when files change                                     |
    |    MISE     | Zoxide      | Smarter cd command for your terminal                                   |

### DEPENDENCIES

- [Git][5]
- [Mise][6]
- [Pre-Commit][7]
- [Gitlint][8]
- [Docker][11]

## USAGE

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
  # ==> docker run -it --rm --user=vscode --workdir=/workspaces/dots --entrypoint=zsh mcr.microsoft.com/devcontainers/ruby:3.4-bookworm

  mise run start --user root --workdir /workspaces/foo
  # ==> docker run -it --rm --user=root --workdir=/workspaces/foo --entrypoint=zsh mcr.microsoft.com/devcontainers/ruby:3.4-bookworm

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
[7]: https://pre-commit.com 'Framework for managing and maintaining multi-language pre-commit hooks'
[8]: https://jorisroovers.com/gitlint 'Git commit message linter'
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
