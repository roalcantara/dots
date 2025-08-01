# NVIM

Yet another Neovim config

[![MIT license](https://img.shields.io/badge/License-MIT-brightgreen.svg?style=flat-square)](LICENSE) [![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg?style=flat-square)][2] [![Editor Config](https://img.shields.io/badge/Editor%20Config-1.0.1-crimson.svg?style=flat-square)][3] [![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)][4]

## STRUCTURE

1. `lua/core/vi`
   1. buffers.lua: Buffer and editor utilities
   2. paths.lua: Path and file system utilities
   3. plugins.lua: Plugin management utilities
   4. root.lua: Project root detection
   5. strings.lua: String manipulation utilities
   6. ui.lua: UI utilities

## USAGE

    ```sh
    nvim
    ```

## DEVELOPMENT

1. **TESTING**

        ```sh
        mise run busted:build
        mise run busted:run
        ```

## ACKNOWLEDGEMENTS

- [Standard Readme][4]

## CONTRIBUTING

- Bug reports and pull requests are welcome on [GitHub][0]
- Do follow [Editor Config][3] rules.
- Everyone interacting in the project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [Contributor Covenant][2] code of conduct.

## LICENSE

The project is available as open source under the terms of the [MIT][1] [License](LICENSE)

[0]: https://github.com/roalcantara/nvim 'Yet another app'
[1]: https://opensource.org/licenses/MIT 'Open Source Initiative'
[2]: https://contributor-covenant.org 'A Code of Conduct for Open Source Communities'
[3]: https://editorconfig.org 'EditorConfig'
[4]: https://github.com/RichardLitt/standard-readme 'Standard Readme'
