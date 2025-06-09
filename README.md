# dots

An opiopnated [DotFiles][10]. Ready to Engage!

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4] [![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg?logo=conventional-commits&style=flat-square)][9]

## INSTALL

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

- List all available tasks

  ```sh
  mise run
  ```

- Start a container with the current directory mounted and the GitHub token secret available

  ```sh
  mise run up
  ```

- Build the container image tagged as dev without cache

  ```sh
  mise run build -t dev --nocache
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
  container-structure-test test --image cockpit:ubuntu-arm64 --config distros/ubuntu/container-structure-test.yml
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
