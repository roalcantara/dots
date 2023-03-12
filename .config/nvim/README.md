# nvim

Neovim configuration

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg)](LICENSE)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)][2]
[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][5]
[![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg)][4]
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-yellow.svg)][3]

## Install

```sh
git clone https://github.com/roalcantara/nvim
```

### Dependencies

- [git][6]

## Usage

- Folder Structure

  > :h rtp

  ```tree
  .
  ├── after
  │   ├── ftplugin
  │   │   └── lua.lua
  │   └── plugin
  │       └── defaults.lua
  ├── init.lua
  ├── LICENSE
  ├── lua
  │   ├── commons.lua
  │   ├── etc
  │   │   └── fn
  │   │       ├── imports.lua
  │   │       └── with_setup.lua
  │   ├── plugins
  │   │   ├── alpha.lua
  │   │   ├── neogit.lua
  │   │   └── tokyonight.lua
  │   └── plugins.lua
  ├── README.md
  └── style.lua
  ```

- Run `npm run clear` to clear the cache
- Run `npm run build` to build the package
- Run `npm run start` to start the server
- Run `npm run start:dev` to start the dev server

## Acknowledgements

- [Standard Readme][5]
- [Medium Neovim for Beginners series][6]
- [A configuration for Neovim beginners][7]

## Contributing

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][4] rules.
- Everyone interacting in the project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [Contributor Covenant][2] code of conduct.

## License

The project is available as open source under the terms of the [MIT][1] [License](LICENSE)

[0]: https://github.com/roalcantara/dots "Neovim"
[1]: https://opensource.org/licenses/MIT "Open Source Initiative"
[2]: https://contributor-covenant.org "A Code of Conduct for Open Source Communities"
[3]: https://conventionalcommits.org "Conventional Commits"
[4]: https://editorconfig.org "EditorConfig"
[5]: https://github.com/RichardLitt/standard-readme "Standard Readme"
[6]: https://alpha2phi.medium.com/learn-neovim-the-practical-way-8818fcf4830f#545a "Medium Neovim for Beginners series"
[7]: https://github.com/alpha2phi/neovim-for-beginner "A configuration for Neovim beginners"
