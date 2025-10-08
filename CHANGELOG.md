## [1.14.7](https://github.com/roalcantara/dots/compare/v1.14.6...v1.14.7) (2025-10-08)


### Bug Fixes

* **install:** Remove mise package manager option ([6e54d9c](https://github.com/roalcantara/dots/commit/6e54d9cf54697514786a86ebebb30918b7977eb4))

## [1.14.6](https://github.com/roalcantara/dots/compare/v1.14.5...v1.14.6) (2025-10-08)


### Bug Fixes

* **install:** Enhance user context handling in run_as_user function ([2d254d8](https://github.com/roalcantara/dots/commit/2d254d82f3dd378adde38ccba3daf4a0a7255671))

## [1.14.5](https://github.com/roalcantara/dots/compare/v1.14.4...v1.14.5) (2025-10-08)


### Bug Fixes

* **install:** Improve Flox's permissions and packages installation ([5348355](https://github.com/roalcantara/dots/commit/53483559471a8b3dc8df1a2afe092d84dd0c0554))

## [1.14.4](https://github.com/roalcantara/dots/compare/v1.14.3...v1.14.4) (2025-10-08)


### Bug Fixes

* **install:** Simplify flox command execution ([cbdd692](https://github.com/roalcantara/dots/commit/cbdd6924330f8b6889ed60e34f02a0250d172172))

## [1.14.3](https://github.com/roalcantara/dots/compare/v1.14.2...v1.14.3) (2025-10-08)


### Bug Fixes

* **install:** Enhance container detection and user context handling ([b20ea4c](https://github.com/roalcantara/dots/commit/b20ea4cea35b4d08fdc7a9ce9ec5c8f0f58717a4))

## [1.14.2](https://github.com/roalcantara/dots/compare/v1.14.1...v1.14.2) (2025-10-07)


### Bug Fixes

* **install:** Replace UNAME checks with is_darwin function ([4867906](https://github.com/roalcantara/dots/commit/4867906be87db9d403fbbb75cfcb1fa47b9c37c9))

## [1.14.1](https://github.com/roalcantara/dots/compare/v1.14.0...v1.14.1) (2025-10-07)


### Bug Fixes

* **install:** Ensure that timezone is valid ([e597080](https://github.com/roalcantara/dots/commit/e59708035b204921bf1ac478579a533c078c56be))
* **install:** Improve timezone configuration handling ([afa5f93](https://github.com/roalcantara/dots/commit/afa5f93d9061ee32fefecb617c337f859dacea48))

# [1.14.0](https://github.com/roalcantara/dots/compare/v1.13.0...v1.14.0) (2025-10-07)


### Features

* **dots:** Add runtime permissions management for XDG environment ([2ea4dc7](https://github.com/roalcantara/dots/commit/2ea4dc7cee2d3f3e2fe97bded70ec7e9a3858867))

# [1.13.0](https://github.com/roalcantara/dots/compare/v1.12.0...v1.13.0) (2025-10-07)


### Features

* **install:** Install packages from default Flox environment ([efd0037](https://github.com/roalcantara/dots/commit/efd0037c31ad79baf5b165ad0a854a68088c668b))
* **kb:** Add TMDB API commands for movie and TV show data retrieval ([4fefeb5](https://github.com/roalcantara/dots/commit/4fefeb54d36623e4133dc6d9e8958081dd50450d))
* **kb:** Enhance SQLite commands ([9c088b9](https://github.com/roalcantara/dots/commit/9c088b9adeee8ab8d7ddd986e278dd314d042008))
* **kb:** Reorganize devops and prep entries ([689a391](https://github.com/roalcantara/dots/commit/689a39143a0576aac2b7c0dcc43124ef446f3f4b))

# [1.12.0](https://github.com/roalcantara/dots/compare/v1.11.0...v1.12.0) (2025-10-01)


### Bug Fixes

* **ci:** Invalidate docker cache on publish workflow ([8f12288](https://github.com/roalcantara/dots/commit/8f1228886ec3ae60ed5276594668b8ea90b2c5f1))
* **ci:** Invalidate docker cache when remote content changes ([7957b5a](https://github.com/roalcantara/dots/commit/7957b5a64786ebfddb0b5a6c57fae3fc730d1ad4))
* **docker:** Update base image references in configuration files ([d7a8e71](https://github.com/roalcantara/dots/commit/d7a8e7140d4d32206dfab306b15a7176602a6141))
* **env:** Add encrypted .env file and .sops.yaml ([2cf7414](https://github.com/roalcantara/dots/commit/2cf7414b845f189c680eaff02575d8f21ea40ad9))
* **install:** Ensure dotfiles clone when necessary ([269825f](https://github.com/roalcantara/dots/commit/269825f0d4d7e0063b3b8cc6397d285bbffa8472))
* **nvim:** Adjust Copilot and blink integration ([22f7665](https://github.com/roalcantara/dots/commit/22f76658b8044750293e7e8fa06048095a170701))
* **nvim:** Fix Visual Multi keybinding to behave like VSCode ([e682f43](https://github.com/roalcantara/dots/commit/e682f430dfa807f349756d03bd77a18cad5f871a))
* **secrets:** Correct secret version ([141ebdb](https://github.com/roalcantara/dots/commit/141ebdb0b143c86728c26a127c086f92eea6f894))
* **secrets:** Correct SOPS scripts ([c7f582c](https://github.com/roalcantara/dots/commit/c7f582c3f98b1c4752afa4a11a29bd5ff0693b57))
* **secrets:** Enhance SOPS/AGE execution and validation ([1ba570b](https://github.com/roalcantara/dots/commit/1ba570b036fff500f9ea63d58e358fe237f79197))


### Features

* **docker:** Ignore venv directories recursively ([b4e32d1](https://github.com/roalcantara/dots/commit/b4e32d11114bd461e87c0054011c67aa3043840a))
* **ghostty:** Add cursor style and click-to-move options ([766e91f](https://github.com/roalcantara/dots/commit/766e91f3c2836a24d19c5cb8662b5d0d08eaa107))
* **install:** Add flox ([6166204](https://github.com/roalcantara/dots/commit/6166204d0b091855506024d19da64c8dca9a71d1))
* **kb:** Add Knowledge Base entries for various tools and techs ([8deab5a](https://github.com/roalcantara/dots/commit/8deab5a539de6105da6d97c0725f65910c6fd547))
* **kb:** Add vi and angular entries ([c45dcf3](https://github.com/roalcantara/dots/commit/c45dcf3ad2c20cd2ff244cb66cd032c4921fb4b7))
* **kb:** Extract, organize and centralize Raycast Snippets ([d3821a7](https://github.com/roalcantara/dots/commit/d3821a70bcf849166986bc8374035e2436bdec4f))
* **kb:** Update some entries ([ba3099d](https://github.com/roalcantara/dots/commit/ba3099df8e20414681fa88c8af9e04e1bbf487f6))
* **nvim:** Add OpenAI API integration and config ([f123a07](https://github.com/roalcantara/dots/commit/f123a078b96acca61aac10d8c798bc221cb3d739))
* **nvim:** Add toggle key mappings ([aa75484](https://github.com/roalcantara/dots/commit/aa7548491c7accb804118850b0d8e4e339b13c31))
* **nvim:** Fix Copilot and Blink integration issues ([980945b](https://github.com/roalcantara/dots/commit/980945bac5eec730a208491cd8d4ce5cd3aecf69))
* **nvim:** Fix line movement to preserve cursor column position ([ab1d16e](https://github.com/roalcantara/dots/commit/ab1d16e0f11c014c674e1cf564f7ac4a09b17b89))
* **xdg:** Add blazing fast XDG environment setup with caching ([98a09d0](https://github.com/roalcantara/dots/commit/98a09d054319ee5aab556b27467266b3f72cdb2e))
* **zsh:** Enable flox loading in ZSH bootstrap ([e42f2ac](https://github.com/roalcantara/dots/commit/e42f2ac920068920a277324ccd5bebeaf337b3b0))
* **zsh:** Setup Flox Default Environment on Startup ([917d8fc](https://github.com/roalcantara/dots/commit/917d8fce391631b2599757741b2aa4813a6af7bc))


### Performance Improvements

* **nvim:** Add standard caching logic ([9c60897](https://github.com/roalcantara/dots/commit/9c608977385f92073eeef97c56415e646969ae6e))
* **zsh:** Improve shell startup ([a024137](https://github.com/roalcantara/dots/commit/a024137de22be535ef5aa75e030108d852dfd62b))

# [1.11.0](https://github.com/roalcantara/dots/compare/v1.10.0...v1.11.0) (2025-09-18)


### Features

* **codestyle:** Add markdownlint configuration and fix violations ([4c2e50d](https://github.com/roalcantara/dots/commit/4c2e50dac7cfb6c7708735e8dc974ce7dc361ee3))
* **fabric:** Add AI library with 200+ analysis and generation patterns ([a035097](https://github.com/roalcantara/dots/commit/a0350978fd0cac295a7f1422fcbda919cd4606fa))
* **fabric:** Add job posting and cover letter generation patterns ([340c0a7](https://github.com/roalcantara/dots/commit/340c0a78d107c24c2d0c2589d60316470098edea))
* **nvim:** Add conventional commit generation ([11e90f7](https://github.com/roalcantara/dots/commit/11e90f7d44598507edead156f7b16390a9d7aba2))
* **nvim:** Add Mini Pairs for automatic pairing ([e28eff2](https://github.com/roalcantara/dots/commit/e28eff2145ba617ae90da07e740cafef7ba670cf))
* **nvim:** Enhance colorscheme configuration ([2549b2b](https://github.com/roalcantara/dots/commit/2549b2b3b38746a11a2697c94debebcb223675f6))
* **nvim:** Refactor keymap definitions ([495b154](https://github.com/roalcantara/dots/commit/495b154e66245fce3f212bfe45f2ec3a4be37c6a))
* **nvim:** Update LuaLS configuration ([1dea424](https://github.com/roalcantara/dots/commit/1dea424d8b6c5387045a7c9a063fafc20e44b5d0))
* **snippets:** Add Biome config and Codility lesson templates ([2e17cbd](https://github.com/roalcantara/dots/commit/2e17cbdb0264e29fdb7f4453aba89a73444de31c))
* **zsh/zim:** Add pnpm shell completion ([549546d](https://github.com/roalcantara/dots/commit/549546d59d2561ee449b490246467ec50dbf7fad))
* **zsh:** Add support for loading API keys from gopass ([4c7f7ab](https://github.com/roalcantara/dots/commit/4c7f7abce8d42c75c1883c36f90f1eb9577cc53f))

# [1.10.0](https://github.com/roalcantara/dots/compare/v1.9.0...v1.10.0) (2025-08-25)


### Bug Fixes

* **install:** Add tree-sitter to mise package list ([cd33e36](https://github.com/roalcantara/dots/commit/cd33e3616128544c5d5ccbb0725ee3d872e0e9f3))


### Features

* **install:** Enhance script with new packers and configuration updates ([97ba3f0](https://github.com/roalcantara/dots/commit/97ba3f0bd587370caaf01b14da60e1477436053a))
* **nvim:** Update configuration and UI components ([9881ea4](https://github.com/roalcantara/dots/commit/9881ea44e662aa1042d6a39ace73b894b4103986))

# [1.9.0](https://github.com/roalcantara/dots/compare/v1.8.0...v1.9.0) (2025-08-16)

### Bug Fixes

* **workflows:** Correct Docker registry URL in preview workflow ([6a9188e](https://github.com/roalcantara/dots/commit/6a9188e4dc389c2c6063893dc5d87884763d908c))

### Features

* **git:** Add AI-powered conventional commit generation ([a79e74c](https://github.com/roalcantara/dots/commit/a79e74c0ad46aa52ce9e44d6d2b5ee4bf063a107))
* **nvim/formater:** Enhance configuration for conform.nvim formatter ([108f201](https://github.com/roalcantara/dots/commit/108f2013821cc8af78d39ada385844ed8386e33e))
* **nvim:** Add user commands and async autocmd setup ([5765f09](https://github.com/roalcantara/dots/commit/5765f0938660aeda9fa1bb88e5a4b680186729ec))
* **ui:** Update UI plugin configuration ([d972701](https://github.com/roalcantara/dots/commit/d972701ed134f2d8cd1508619a4e8b1c6a664277))

# [1.8.0](https://github.com/roalcantara/dots/compare/v1.7.0...v1.8.0) (2025-08-12)

### Features

* **install:** Enhance support for Ubuntu and improve user handling ([57562de](https://github.com/roalcantara/dots/commit/57562ded12f5f4cd84c3004ce8620a7cd4730ae1))

# [1.7.0](https://github.com/roalcantara/dots/compare/v1.6.0...v1.7.0) (2025-08-12)

### Features

* **opencode:** Add global configuration file ([eb67729](https://github.com/roalcantara/dots/commit/eb67729ec3fe425a99367306cbd4fc0fe287c910))

# [1.6.0](https://github.com/roalcantara/dots/compare/v1.5.7...v1.6.0) (2025-08-12)

### Bug Fixes

* **ci:** Streamlined output handling and improve readability ([fb773ad](https://github.com/roalcantara/dots/commit/fb773ad5920e16b90fe115b97e034009c8a36c7a))
* **install:** Removed gh installation in package list ([dd8d3a3](https://github.com/roalcantara/dots/commit/dd8d3a392e8dde505db4b745b971d0e4591a0c76))

### Features

* **bat:** Add configuration and README files for `bat` setup ([0a29db9](https://github.com/roalcantara/dots/commit/0a29db9b21fb9424a2063c99e2a5638199b605da))
* **gitlint:** Add gitlint configuration file for commit message rules ([9d87416](https://github.com/roalcantara/dots/commit/9d87416c0e211755368eabcb5edcf6e3780f64d7))

## [1.5.7](https://github.com/roalcantara/dots/compare/v1.5.6...v1.5.7) (2025-08-06)

### Bug Fixes

* **workflows:** Use the correct secret GITHUB_TOKEN ([2305aff](https://github.com/roalcantara/dots/commit/2305aff89be8e7ceec358cf3fcc0078497a18f65))

## [1.5.6](https://github.com/roalcantara/dots/compare/v1.5.5...v1.5.6) (2025-08-06)

### Bug Fixes

* **install:** Update Ruby environment setup in installation script ([bd44a6e](https://github.com/roalcantara/dots/commit/bd44a6e956a6d8ec7f87f205e9cf739fe747f3f6))

## [1.5.5](https://github.com/roalcantara/dots/compare/v1.5.4...v1.5.5) (2025-08-04)

### Bug Fixes

* **install:** Correct function name for setting perms on XDG_RUNTIME_DIR ([e46609a](https://github.com/roalcantara/dots/commit/e46609a3eb3fbe80fe6cbd7f4b855402a07d4710))

## [1.5.4](https://github.com/roalcantara/dots/compare/v1.5.3...v1.5.4) (2025-08-04)

### Bug Fixes

* **install:** Update function name for setting permissions ([3e4e7ca](https://github.com/roalcantara/dots/commit/3e4e7cadfce22ab2172b2aeb464fcbd5dbd49773))

## [1.5.3](https://github.com/roalcantara/dots/compare/v1.5.2...v1.5.3) (2025-08-04)

### Bug Fixes

* **install:** Correct function name for setting XDG_RUNTIME_DIR perms ([6d376b8](https://github.com/roalcantara/dots/commit/6d376b8a4502ec41de8d6e737801073adfada8e7))
* **workflows:** Add GITHUB_TOKEN secret to Docker preview workflows ([78c53d4](https://github.com/roalcantara/dots/commit/78c53d41c5e6b1c82db83829bd0c0e66dd5321d3))

## [1.5.2](https://github.com/roalcantara/dots/compare/v1.5.1...v1.5.2) (2025-08-04)

### Bug Fixes

* **workflows:** Add prefix to SHA tag in Docker build/publish workflows ([aeef841](https://github.com/roalcantara/dots/commit/aeef8419a9095fed3ec900b01d9460451973ed96))
* **zsh:** Ensure proper creation and permissions for XDG_RUNTIME_DIR ([0cdd929](https://github.com/roalcantara/dots/commit/0cdd92976df07ee91325b1e5ab12bbbb6e7eb5d7))

## [1.5.1](https://github.com/roalcantara/dots/compare/v1.5.0...v1.5.1) (2025-08-04)

### Bug Fixes

* **install:** Use sudo for changing user shell to ensure proper perms ([10d4c1c](https://github.com/roalcantara/dots/commit/10d4c1ce6a124a4ffda7986d88277c94099008be))
* **workflos/publish:** Remove 'v' prefix from version ([cdb777e](https://github.com/roalcantara/dots/commit/cdb777eccb67e0fe4828d3f659d8a655ad18b621))

# [1.5.0](https://github.com/roalcantara/dots/compare/v1.4.0...v1.5.0) (2025-08-04)

### Bug Fixes

* **install:** Improve user/group detection and ownership setup ([5c75eab](https://github.com/roalcantara/dots/commit/5c75eab433dbb989aadebf93714a722f5c802ce7))

### Features

* **nvim:** Update Neovim packages ([af614d6](https://github.com/roalcantara/dots/commit/af614d644551219dd2241910e4d7e7f8befd9403))
* **zsh:** Enhance XDG and ZSH folders setup ([3086083](https://github.com/roalcantara/dots/commit/3086083f45e507eed5ec84e70a4afa4fb9037d7a))

# [1.4.0](https://github.com/roalcantara/dots/compare/v1.3.0...v1.4.0) (2025-08-03)

### Features

* **install/nvim:** Enhance LSP and Mason integration ([fa12017](https://github.com/roalcantara/dots/commit/fa120173da3c7e5a35ce04e49871d99792dc38cc))
* **install:** Add timeout handling for provider setup ([f4175c3](https://github.com/roalcantara/dots/commit/f4175c347fb6ea55e09eb75ca91f753a24571892))
* **install:** Refactor provider setup for sequential execution ([0025df1](https://github.com/roalcantara/dots/commit/0025df1e287263987748dcedb5449410b2986d88))

# [1.3.0](https://github.com/roalcantara/dots/compare/v1.2.1...v1.3.0) (2025-08-01)

### Bug Fixes

* **install:** Update Node.js version ([f8be74e](https://github.com/roalcantara/dots/commit/f8be74e9c3cc64b860b2a6366eef0e3ce9bd4856))

### Features

* **ripgrep:** Add configuration file for ripgrep with custom settings ([cf3a62d](https://github.com/roalcantara/dots/commit/cf3a62df845e82b7f6cf2aa1b3de2e2e95761bfe))

## [1.2.1](https://github.com/roalcantara/dots/compare/v1.2.0...v1.2.1) (2025-08-01)

### Bug Fixes

* **install:** Enhance user detection ([c76b85f](https://github.com/roalcantara/dots/commit/c76b85ff18e41541954fa4438bcc3211f8283420))

# [1.2.0](https://github.com/roalcantara/dots/compare/v1.1.0...v1.2.0) (2025-08-01)

### Features

* **zsh:** Update syntax highlighting module to fast-syntax-highlighting ([b62bfcf](https://github.com/roalcantara/dots/commit/b62bfcfa37722def78d82204bd86edcc83d9160e))

# [1.1.0](https://github.com/roalcantara/dots/compare/v1.0.0...v1.1.0) (2025-08-01)

### Features

* **config:** Add initial Ghostty configuration file ([dca96bb](https://github.com/roalcantara/dots/commit/dca96bba672f829b20156e11b8c0b693e3859212))
* **nvim/tests:** Add Busted configuration and initial test setup ([389686e](https://github.com/roalcantara/dots/commit/389686e70810377bc310e997d552bfdc227ab185))

# 1.0.0 (2025-07-30)

### Bug Fixes

* **install:** Correct Neovim setup command syntax ([331d4c3](https://github.com/roalcantara/dots/commit/331d4c37f7663117f0cff6ad9fa3b06c9a99a69a))
* **install:** Fix argument to specify the repo ([899a5ac](https://github.com/roalcantara/dots/commit/899a5ac97adf08d5707fb7d33504feca346fa57a))
* **install:** Run nvim setup providers in parallel ([072830c](https://github.com/roalcantara/dots/commit/072830ce42feb061323e4db80f3522465efc794e))
* **install:** Setup and cleanup GitHub token ([e7e4658](https://github.com/roalcantara/dots/commit/e7e4658cd763762a621b0f4546fb8716d0f03652))
* **install:** Standardize log message formatting with checkmark symbols ([ae69bbb](https://github.com/roalcantara/dots/commit/ae69bbb73e4f0d5d0453754864c25543a12f4593))
* **install:** Update log messages for repository URL formatting ([f791988](https://github.com/roalcantara/dots/commit/f791988d70300098be32d6be24d4cf7b16e0acdb))
* **install:** Update Neovim plugin installation and configuration ([22d648b](https://github.com/roalcantara/dots/commit/22d648b4192c4f62cf5b98a5a2ada9244ffafab2))
* **install:** Update symlink for ~/.config ([30f314a](https://github.com/roalcantara/dots/commit/30f314a8e13f1e42cec14f578130698fef7718cd))
* **nvim:** Enable clipboard in containers ([219cdd9](https://github.com/roalcantara/dots/commit/219cdd9d8845845ae3db9afc2b6d1468fb934a69))
* **zsh:** Correct syntax in .zshrc for plugin manager and initialization ([e47ac97](https://github.com/roalcantara/dots/commit/e47ac9744c90e45e432f5d2360240934ca0f5917))

### Features

* **ci:** Add semantic-release configuration and workflow ([f2d9356](https://github.com/roalcantara/dots/commit/f2d935631a0169d850e7111d8b9bd3a6d3c8814e))
* **ci:** Add workflow to deploy to Docker Hub on new releases ([4a4f1e2](https://github.com/roalcantara/dots/commit/4a4f1e23e46ef9bf86800b10252c52ad41fd463c))
* **docker:** Add Alpine-based Dockerfile for development environment ([46f893a](https://github.com/roalcantara/dots/commit/46f893a0023dde4416fffbd7b583dc56c46b3bd6))
* **editorconfig:** Enhance Lua configuration and formatting options ([de9dc6e](https://github.com/roalcantara/dots/commit/de9dc6ef55efe363a2ade1b3d03e1fe5b1c56aab))
* **git:** Add configuration files for Git setup ([d6f3cee](https://github.com/roalcantara/dots/commit/d6f3cee20b35aefe86d5fc404c9c6250c9478dbc))
* **homebrew:** Add and Setup Brew and Brewfile for package management ([350d987](https://github.com/roalcantara/dots/commit/350d987d5a8d9729e143ff5e423d019b764b0355))
* **install:** Add branch support ([a650134](https://github.com/roalcantara/dots/commit/a650134823b0f8d6593e9c5642e9e12f38fe55a0))
* **install:** Add gum to mise global installation ([a261c91](https://github.com/roalcantara/dots/commit/a261c9170fe72116fcf8945163b497a51e23742d))
* **install:** Add Neovim setup to installation script ([f941d43](https://github.com/roalcantara/dots/commit/f941d4301eac9743ae98f1ecf3cc5e92593a76b5))
* **install:** Enhance Neovim setup with NPM, Python, and Ruby providers ([1ee8733](https://github.com/roalcantara/dots/commit/1ee8733f6f7955feebe85e538b3583390538cbc9))
* **install:** Enhance package management and platform detection ([8ed2473](https://github.com/roalcantara/dots/commit/8ed24733b391c5efbb82b5af070975db6927c32f))
* **install:** Enhance script and ZSH config for improved setup ([28b2d8e](https://github.com/roalcantara/dots/commit/28b2d8ec6c198e2a4caef7c7d6f7a874cfcf8f5c))
* **install:** Enhance script with logging and improved cleanup ([7254148](https://github.com/roalcantara/dots/commit/7254148ec6eb82242dbe34395be45ed3ac3d49cc))
* **install:** Ensure the dependencies to build fzf-tab binaries ([d54e6b3](https://github.com/roalcantara/dots/commit/d54e6b3e8b61c0e0d661d61a9544acceae9a5337))
* **install:** Install and setup mise ([eb1a8c2](https://github.com/roalcantara/dots/commit/eb1a8c26f1bb0a3aa274710b981a4664879c5022))
* **install:** Remove ruby from mise global packages ([ea286d8](https://github.com/roalcantara/dots/commit/ea286d886111e1d80c974a0e323f3cd60e868e23))
* **install:** Set ZDOTDIR environment variable for ZSH configuration ([ec0d68b](https://github.com/roalcantara/dots/commit/ec0d68b8102892c55710d39f767fb3947bdbf27d))
* **install:** Setup for XDG directories ([c32194d](https://github.com/roalcantara/dots/commit/c32194d671c3b3d7e1a177a9134564406a0482fc))
* **install:** Streamline installation script ([21c84c4](https://github.com/roalcantara/dots/commit/21c84c41746b874c169cf826b410657ca8e9b5f2))
* **install:** Update backup resources and XDG common directories ([bddbf83](https://github.com/roalcantara/dots/commit/bddbf838e24ed38d0f1896b8f2e30944015fe689))
* **install:** Update Neovim Python setup to use 'uv' instead of pip ([6d91a41](https://github.com/roalcantara/dots/commit/6d91a41957f00f4912284eb779e19a80911e7603))
* **install:** Update Python package installation and enhance mise.toml ([172d6af](https://github.com/roalcantara/dots/commit/172d6af1d1486e77af61797eeab149272a475104))
* **install:** Update script and Dockerfile to use Debian distribution ([b524da6](https://github.com/roalcantara/dots/commit/b524da605dce5ca99174e619560371f677e97a21))
* **mise:** Enhance Container Structure Test configuration and usage ([4477fc3](https://github.com/roalcantara/dots/commit/4477fc3325497956fdb29dde0f5d51358c29a150))
* **nvim:** Add Docker support and performance analysis tools ([8fb30cb](https://github.com/roalcantara/dots/commit/8fb30cbb59a03af6d819ca4ade3a261796f42597))
* **nvim:** Add NVIM configuration ([ce9c695](https://github.com/roalcantara/dots/commit/ce9c695d53c3a7cef8d263e6de8a078e38232893))
* **nvim:** Configure linters and formattters ([5078ddc](https://github.com/roalcantara/dots/commit/5078ddc718531cc4763b66d7a6376a16915ee6ca))
* **nvim:** Introduce Avante plugin for AI integration ([6bb681e](https://github.com/roalcantara/dots/commit/6bb681e661cb7b96ab0622f9565418c07863859f))
* **nvim:** Update configuration files and enhance plugin management ([7f223e3](https://github.com/roalcantara/dots/commit/7f223e3b9971248b1c034b59b5ce53290f9a2798))
* **snippets:** Add various snippets for enhanced coding experience ([1b69e9b](https://github.com/roalcantara/dots/commit/1b69e9b5418b290127a031767040d1bf27a44592))
* **snippets:** Enhance shell script snippets with additional prefixes and structured bodies ([2fdcea3](https://github.com/roalcantara/dots/commit/2fdcea36997c31e62e619735688813854164a311))
* **starship:** Add and setup Starship ([d942426](https://github.com/roalcantara/dots/commit/d9424267b8d239c168765f2dbdb90de1858bb46d))
* **starship:** Update configuration for enhanced functionality ([2259c06](https://github.com/roalcantara/dots/commit/2259c0612345b560bd3979aebc099adb230db8b5))
* **starship:** Update prompt format ([65272a7](https://github.com/roalcantara/dots/commit/65272a756f76b0cd74b6f60533bf40bb619e3b94))
* **zsh:** Add ANSI to HEX color conversion in dots function ([4112e01](https://github.com/roalcantara/dots/commit/4112e01718ff6e6a5c24147ab17f1704edf8c282))
* **zsh:** Add Cargo environment variables for Rust development ([278273d](https://github.com/roalcantara/dots/commit/278273dbe773b83cc170d21bffdd03c21975cbde))
* **zsh:** Add Doppler completion script and update .zimrc ([f915abc](https://github.com/roalcantara/dots/commit/f915abc3f82d4080b1b01e80cfc6a4c0c9eaff7d))
* **zsh:** Add dotfile management and profiling ([e007941](https://github.com/roalcantara/dots/commit/e007941f0980ea05e9d6ff9cd9125c1c4aeb39fe))
* **zsh:** Add keyring function ([d29e275](https://github.com/roalcantara/dots/commit/d29e27568940fbb38599a3416db11a361022691f))
* **zsh:** Add mise command activation to .zprofile ([e0a5b45](https://github.com/roalcantara/dots/commit/e0a5b45c1f9533257bdb540791146cc059156a02))
* **zsh:** Add theme configuration for improved terminal aesthetics ([2f08dde](https://github.com/roalcantara/dots/commit/2f08ddef3aaef3ac4ad3e5e2ce5b77b18dd79183))
* **zsh:** Add XDG_BIN_HOME to environment configuration ([1e8813a](https://github.com/roalcantara/dots/commit/1e8813aabdbe269d4c2843acef1a66df5f0bf955))
* **zsh:** Add zoxide module and update installation scripts ([a45e8ff](https://github.com/roalcantara/dots/commit/a45e8ff9ecb516e2595e9a6d6a7633069b481157))
* **zsh:** Always loads zprofile when loading zshenv ([72ebc1b](https://github.com/roalcantara/dots/commit/72ebc1b7bdf873667c2c73b5cb6c490082bc7882))
* **zsh:** Enhance .zprofile improving environment variable management ([d45a3ed](https://github.com/roalcantara/dots/commit/d45a3ed17c55055f57068702879e229052f4ea73))
* **zsh:** Enhance .zshenv with XDG directory setup ([527a281](https://github.com/roalcantara/dots/commit/527a28103055269a47e378266843d01b0c5007b2))
* **zsh:** Enhance zsh environment setup and functions ([815ca81](https://github.com/roalcantara/dots/commit/815ca81b8d98e7ae8fc9d697756f7ad7aa78ace3))
* **zsh:** Improve configuration files organization and functionality ([1856338](https://github.com/roalcantara/dots/commit/1856338026a03a14f210aafcc6efd4f79c3f070e))
* **zsh:** Move Starship and NVIM configurations to .zshrc ([ff8bf0e](https://github.com/roalcantara/dots/commit/ff8bf0e6a654bfcf7486cc599a36400f4e580e68))
* **zsh:** Refactor MISE configuration and remove init.zsh ([e425b1e](https://github.com/roalcantara/dots/commit/e425b1e792b3462129f385e46a6533245cba8747))
* **zsh:** Replace oh-my-zsh submodule with ZIM configuration ([e5211fd](https://github.com/roalcantara/dots/commit/e5211fd6f71d235cd7efd84091514f0af12868b7))
* **zsh:** Set MISE_GLOBAL_CONFIG_FILE environment variable ([916c068](https://github.com/roalcantara/dots/commit/916c068bcd494930efe14a95f8b30c47711a0384))
* **zsh:** Source .zshrc in .zprofile ([de9eeab](https://github.com/roalcantara/dots/commit/de9eeabe476043277cb439489a4032e58a874e16))
