# dots

An opinionated [DotFiles][10]. Ready to Engage!

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## INSTALL

### One-liner Installation (Recommended)

```sh
curl -fsSL "https://raw.githubusercontent.com/roalcantara/dots/main/install" | bash
```

### Using Go CLI

```sh
go install github.com/roalcantara/dots/cmd/dots@latest
dots
```

The Go CLI supports various flags to customize the installation:

```sh
dots --help  # Show all available options

# Example: Install without Neovim and ownership changes
dots --nvim=false --chown=false
```

### Manual Installation

```sh
git clone https://github.com/roalcantara/dots
```

### DEPENDENCIES

- [Git][5]
- [Mise][6]
- [Pre-Commit][7]
- [Gitlint][8]
- [Docker][11]

## USAGE

### BUILDING

#### OVEREVIEW

- **Features**

  - 🔍 **Validation:** Checks for Dockerfile existence and valid platforms
  - 🚀 **Post-actions**: Push, run, and inspect in one command
  - 🎯 **Flexibility:** Supports different repos, branches, and install args
  - 🔐 **Security:** Better token handling with multiple sources
  - 📊 **Insights:** Detailed image information and build summary
  - 🐛 **Debugging:** Enhanced logging and error messages
  - 💫 **UX:** Color-coded output with progress indicators

- **What it DOES do?**

  - ✅ Provides clean base environment _(devcontainer base)_
  - ✅ Sets minimal essential environment variables
  - ✅ Passes GitHub token securely if provided
  - ✅ Executes install script exactly as documented
  - ✅ Shows what the install script actually created
  - ✅ Uses whatever shell the install script configured

#### BUILDING USAGE

- Basic Usage

 ```sh
  # Basic build
  mise run build

  # Build the container image tagged as dev without cache
  mise run build -t dev --nocache

  # Test different scenarios
  mise run build --distro ubuntu --platform amd64 --tag dev
  mise run build --branch develop --args "--verbose --debug --username=foo --groupname=bar"
  mise run build --repo "youruser/dotfiles" --branch main

  # Build and immediately test
  mise run build --run

  # Build and inspect results
  mise run build --inspect

  # Build without cache and push
  mise run build --nocache --push

  # Build with custom install script arguments
  mise run build --args "--minimal --no-zsh" --tag minimal

  # Debug build issues
  mise run build --logs --nocache

  # Test on different platforms
  mise run build --platform arm64 --distro alpine --run
```

- Advanced Usage

 ```sh
    # Test private repository
    export GITHUB_TOKEN="your_token"
    mise run build --repo "private/repo" --branch private-branch

    # Test different base images
    mise run build --distro ubuntu-minimal --tag lightweight

    # Build and push to registry
    export DOCKER_REGISTRY="ghcr.io/username"
    mise run build --push --tag latest

    # Test install script with specific arguments
    mise run build --args "--skip-zsh --minimal-vim" --tag custom
 ```

### TESTING

- Install [CST (Container Structure Tests)][12]

  ```sh
  brew install container-structure-test
  ```

- Build the image for testing

  ```sh
  mise run build --distro ubuntu --platform arm64 -t testing --nocache
  ```

- Run the Container Structure Tests

  ```sh
  container-structure-test test --image dots:ubuntu-arm64-dev --config distros/ubuntu/container-structure-test.yml
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
