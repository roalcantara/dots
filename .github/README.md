# dots

[![Build](https://github.com/roalcantara/dots/actions/workflows/build.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/build.yml) [![Release](https://github.com/roalcantara/dots/actions/workflows/release.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/release.yml) [![Publish](https://github.com/roalcantara/dots/actions/workflows/publish.yml/badge.svg)](https://github.com/roalcantara/dots/actions/workflows/publish.yml)

Configuration files

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)][2]
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)][3]
[![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg)][4]
[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][5]

## Install

- Download to `~/.dots` - using `git`, `curl` or `wget`

  ```sh
  curl -Lks https://raw.githubusercontent.com/roalcantara/dots/main/script/setup | bash
  ```

  >💡 **NOTE:** If **macOS**, the script updates the system and installs [Xcode Command Line Tools][9] - which includes `git` and `make`. Roughly something like [this][10]..
  >
  > ```sh
  > sudo softwareupdate -ia && xcode-select -p
  > ```

### Dependencies

- [git][6]

## Usage

- Alternatively, clone manually into the desired location

    ```sh
    git clone --bare https://github.com/roalcantara/dots.git ~/.dots
    ```

- Create alias `d` to interact with the repository - instead of the regular `git`

    ```sh
    alias d='/usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'
    ```

- Checkout the actual content from the bare repository to `$HOME`

    ```sh
    d checkout main
    ```

- After the setup, `$HOME`'s files can be versioned replacing `git` with the newly created alias `d`, _i.e._:

    ```sh
    d status
    d touch .vimrc
    d add .vimrc
    d commit -m "feat(vi): Add vimrc"
    d log
    d push
    ```

## Acknowledgements

- [Standard Readme][5]
- [Conventional Commits][3]
- [Unofficial guide to dotfiles on GitHub][7]
- [Dotfiles: Best Way to Store in a Bare Git Repository][8]

## Contributing

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][4] rules.
- Everyone interacting in the project is expected to follow the [Contributor Covenant][2] code of conduct.

## License

The project is available as open source under the terms of the [MIT][1] [License](LICENSE)

[0]: https://github.com/roalcantara/dots "Dotfiles"
[1]: https://opensource.org/licenses/MIT "Open Source Initiative"
[2]: https://contributor-covenant.org "A Code of Conduct for Open Source Communities"
[3]: https://conventionalcommits.org "Conventional Commits"
[4]: https://editorconfig.org "EditorConfig"
[5]: https://github.com/RichardLitt/standard-readme "Standard Readme"
[6]: https://git-scm.com "Git"
[7]: https://dotfiles.github.io "Unofficial guide to dotfiles on GitHub"
[8]: https://atlassian.com/git/tutorials/dotfiles "Dotfiles: Best Way to Store in a Bare Git Repository"
[9]: https://mac.install.guide/commandlinetools/4.html "Install Xcode Command Line Tools"
[10]: https://developer.apple.com/forums/thread/698954 "Automate the Install of Xcode Command Line Tools"
