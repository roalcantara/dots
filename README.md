# dots

An opinionated [DotFiles][10]. Ready to Engage!

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## INSTALL

At the moment, the `install` script is only handles `debian` distros.

- One-liner Installation script

    ```sh
    # user:roalcantara, group:wheel
    curl -fsSL "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash

    # customizing user and group
    curl -fsSL "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash -s -- -u "vscode" -g "vscode"
    ```

- Regular Installation

    ```sh
    # Clone the repository and run the install script (roalcantara:wheel)
    git clone https://github.com/roalcantara/dots ~/.local/share/dots && ~/.local/share/dots/install

    # Clone the repository and run the install script with customization (vscode:vscode)
    git clone https://github.com/roalcantara/dots ~/.local/share/dots && ~/.local/share/dots/install -u "vscode" -g "vscode"
    ```

### OVEREVIEW

- **Features**

  - ✅ Installation script to setup a development environment
  - ✅ Ready to be used in DevContainers
  - ✅ Uses whatever shell the install script configured

- **DevContainer**

  - ✅ Provides essential environment and tools to start developing
  - ✅ Installs essential tools and dependencies via [Mise][6]

- **Tooling**

  - ✅ [Mise][6] to manage tools and dependencies
  - ✅ [ZSH][15] as default shell
  - ✅ [Starship][16] as prompt
  - ✅ [Git][5] as version control system
  - ✅ [Gitlint][8] to manage git commit messages
  - ✅ [Pre-Commit][7] to manage pre-commit hooks
  - ✅ [Docker][11] to manage container images
  - ✅ [CST (Container Structure Tests)][12] to validate the structure of your container images
  - ✅ [OCI Best Practices Image Annotations][13] to validate the structure of your container images

### DEPENDENCIES

- [Git][5]
- [Mise][6]
- [Pre-Commit][7]
- [Gitlint][8]
- [Docker][11]

## USAGE

### BUILDING

At the moment, the `build` task is only available for the `debian` distro.

 ```sh
  mise run build
  # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --build-arg=BRANCH=main --build-arg=GITHUB_REPO=roalcantara/dots --platform=linux/arm64 --secret=id=github_token,src=./.secrets/github_token.secret --tag=dots:debian-arm64-dev --file=distros/debian/Dockerfile .

  mise run build --tag local
  mise run build --tag testing --nocache
  mise run build --tag latest --platform amd64
  mise run build --tag runtime --nocache --runtime
  # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --build-arg=BRANCH=main --build-arg=GITHUB_REPO=roalcantara/dots --platform=linux/arm64 --no-cache --secret=id=github_token,src=./.secrets/github_token.secret --tag=dots:debian-arm64-runtime --file=distros/debian/Dockerfile.runtime .

  mise run build --tag runtime --nocache --runtime --platform amd64
  # ==> DOCKER_BUILDKIT=1 docker build --build-arg=BUILDKIT_INLINE_CACHE=1 --build-arg=BRANCH=main --build-arg=GITHUB_REPO=roalcantara/dots --platform=linux/amd64 --no-cache --secret=id=github_token,src=./.secrets/github_token.secret --tag=dots:debian-amd64-runtime --file=distros/debian/Dockerfile.runtime .
```

#### RUNNING

At the moment, the `start` task is only available for the `debian` distro.

 ```sh
  mise run start --tag dev
  # => docker run -it --tty --rm --user=vscode --workdir=/workspaces/dots dots:debian-arm64-dev

  mise run start --tag local --platform amd64
  # => docker run -it --tty --rm --user=vscode --workdir=/workspaces/dots dots:debian-amd64-local

  mise run start
  # => docker run -it --tty --rm --user=vscode --workdir=/workspaces/dots --entrypoint=zsh mcr.microsoft.com/devcontainers/ruby:3.4-bookworm

  mise run start --user root --workdir /workspaces/foo
  # => docker run -it --tty --rm --user=root --workdir=/workspaces/foo --entrypoint=zsh mcr.microsoft.com/devcontainers/ruby:3.4-bookworm
```

### TESTING

1. Install [CST (Container Structure Tests)][12]

    ```sh
    brew install container-structure-test
    ```

2. Build the image for testing

    ```sh
    mise run build --nocache --platform amd64 --tag testing
    ```

3. Run the Container Structure Tests

    ```sh
    # via mise
    mise run test --platform amd64 --tag testing

    # via container-structure-test
    container-structure-test test --image dots:debian-amd64-testing --config distros/debian/container-structure-test.yml
    ```

## ACKNOWLEDGEMENTS

- [Standard Readme][4]
- [Conventional Commits][9]
- [Dotfiles][10]
- [CST (Container Structure Tests)][12]
- [OCI Best Practices Image Annotations][13]
- [Multi-arch build and images the simple way][14]

## CONTRIBUTING

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][3] rules.
- Everyone interacting in the project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [Contributor Covenant][2] code of conduct.

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
