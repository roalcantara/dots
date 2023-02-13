# [nvim][1]

The hyperextensible Vim-based text editor

[![neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)](https://neovim.com)
[![lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://lua.com)

## Structure

```tree
nvim ($MYVIMRC)
│── init.vim
├── etc
│   │── mappings.vim
│   │── plugins.vim
│   │── settings.vim
│   └── theme.vim
└── opt
```

### [/etc](etc/README.md)

Especific system configurations

### [/opt](opt/README.md)

Config files for add on application software

## [Startup Files][5]

The configuration files are read in the following order

### vim.init

1.  etc/conf/settings.vim
2.  etc/conf/plugins.vim
3.  etc/conf/mappings.vim
4.  etc/conf/theme.vim
5.  opt/plugins/spellcheck.vim
6.  opt/plugins/index.vim

## Installation

1. pynvim

   ```sh
   python2 -m pip install pynvim
   python2 -m pip install neovim

   python -m pip install pynvim
   python3 -m pip install neovim
   ```

2. ruby vim

   ```sh
   gem update --system
   gem outdated
   gem update
   gem cleanup
   gem environment # to ensure the gem bin directory is in $PATH
   gem install neovim # to ensure the neovim RubyGem is installed
   ```

3. node vim

   ```sh
   npm install -g neovim
   ```

4. perl

   ```sh
   cpanm -n App::cpanminus
   cpanm -n Neovim::Ext
   ```

## Usage

1. Edit the initialization file

   ```sh
   vi ~/.config/nvim/init.vim
   ```

2. Theme

   ```sh
   nvim/src/core/theme/init.moon
   nvim/src/core/theme/icons.moon
   nvim/src/core/theme/palette.moon
   ```

3. Plugins

   ```sh
   nvim/src/core/plugins.moon
   ```

   1. Plugins are managed by packer, with followwing commands:

   -

4. Check Health

   ```sh
   health#coc#check
   ========================================================================
     - OK: Environment check passed

     - OK: Javascript bundle build/index.js found
     - OK: Service started

   health#nvim#check
   ========================================================================
   ## Configuration
     - OK: no issues found

   ## Performance
     - OK: Build type: Release

   ## Remote Plugins
     - OK: Up to date

   ## terminal
     - INFO: key_backspace (kbs) terminfo entry: key_backspace=\177
     - INFO: key_dc (kdch1) terminfo entry: key_dc=\E[3~
     - INFO: $COLORTERM='truecolor'

   health#provider#check
   ========================================================================
   ## Clipboard (optional)
     - OK: Clipboard tool found: pbcopy

   ## Python 2 provider (optional)
     - INFO: Using: g:python_host_prog = "/usr/bin/python2"
     - INFO: Executable: /usr/bin/python2
     - INFO: Python version: 2.7.16
     - INFO: pynvim version: 0.4.2
     - OK: Latest pynvim is installed.

   ## Python 3 provider (optional)
     - INFO: Using: g:python3_host_prog = "/usr/local/bin/python3"
     - INFO: Executable: /usr/local/bin/python3
     - INFO: Python version: 3.9.1
     - INFO: pynvim version: 0.4.2
     - OK: Latest pynvim is installed.

   ## Ruby provider (optional)
     - INFO: Ruby: ruby 3.0.0p0 (2020-12-25 revision 95aff21468) [x86_64-darwin20]
     - INFO: Host: /usr/local/bin/neovim-ruby-host
     - OK: Latest "neovim" gem is installed: 0.8.1

   ## Node.js provider (optional)
     - INFO: Node.js: v15.8.0
     - INFO: Neovim node.js host: /usr/local/bin/neovim-node-host
     - OK: Latest "neovim" npm/yarn package is installed: 4.9.0
   ```

5. Lua

## Setup

- brew install --HEAD luajit
- brew install --HEAD neovim

### LuaRocks

1. Homebrew

   - brew install --HEAD luarocks
   - luarocks --version
   - luarocks config --lua-dir=/usr/local/opt/luajit-openresty

2. Nix

   1. Add to `~/.config/nix/home-manager/packages/default.nix`

      ```nix
      { config, pkgs, lib, ... }:
      {
        deps = with pkgs; [
        # ...
        luajit # https://bit.ly/3Hc2PZ5 · High-performance JIT compiler for Lua 5.1
        pkgs.luajitPackages.luarocks # · https://bit.ly/3aNjR3p Lua pack manager
        # ...
      }
      ```

   2. Add to `/.config/nix/home-manager/programs/direnv/default.nix`

      ```nix
        # Usage:
        #      export LUA_ROCKS_HOME=$XDG_DATA_HOME/luarocks
        #      layout luarocks
        #
        # Sets up environment for Luarocks
        layout_luarocks() {
          PATH_add "$LUA_ROCKS_HOME"/bin
        }
      ```

   3. Build the system

      ```sh
      TERM=xterm-256color ~/.config/result/sw/bin/darwin-rebuild switch --flake ~/.config
      ```

   4. Add to the project's `.envrc`

      ```sh
      use asdf

      export LUA_ROCKS_HOME=$XDG_DATA_HOME/luarocks
      layout luarocks
      ```

   5. Run `direnv allow`
   6. Check luarocks installation

      ```sh
      ~> luarocks
      # =>
      # Usage: .luarocks-wrapped [-h] [--version] [--dev] [--server <server>]
      #       [--only-server <server>] [--only-sources <url>]
      #       [--namespace <namespace>] [--lua-dir <prefix>]
      #       [--lua-version <ver>] [--tree <tree>] [--local] [--global]
      #       [--verbose] [--timeout <seconds>] [--pin] [<command>] ...
      #
      # LuaRocks 3.8.0, the Lua package manager
      # ..
      # Configuration:
      #
      #  Lua:
      #      Version    : 5.1
      #      Interpreter: /nix/store/2x3j2pvxmgcf4q4i1g64navwd7vnz7ra-luajit-2.1.0-2022-04-05/bin/luajit (ok)
      #      LUA_DIR    : /nix/store/2x3j2pvxmgcf4q4i1g64navwd7vnz7ra-luajit-2.1.0-2022-04-05 (ok)
      #      LUA_BINDIR : /nix/store/2x3j2pvxmgcf4q4i1g64navwd7vnz7ra-luajit-2.1.0-2022-04-05/bin (ok)
      #      LUA_INCDIR : /nix/store/2x3j2pvxmgcf4q4i1g64navwd7vnz7ra-luajit-2.1.0-2022-04-05/include/luajit-2.1 (ok)
      #      LUA_LIBDIR : /nix/store/2x3j2pvxmgcf4q4i1g64navwd7vnz7ra-luajit-2.1.0-2022-04-05/lib (ok)
      #
      #  Configuration files:
      #      System  : /nix/store/jmrx4v2k7kvvkymfzm3gzysy19sbpdgk-luarocks-3.8.0/etc/luarocks/config-5.1.lua (ok)
      #      User    : ~/.config/luarocks/config-5.1.lua (ok)
      #
      #  Rocks trees in use:
      #      ~/.cache/luarocks ("user")
      #      ~/.local/share/luarocks ("system")
      ```

   7. Install lua rocks

      ```sh
      ~> luarocks install luacov busted luacheck inspect
      # =>
      # Installing https://luarocks.org/luacheck-0.26.1-1.src.rock
      # luacheck 0.26.1-1 depends on lua >= 5.1 (5.1-1 provided by VM)
      # luacheck 0.26.1-1 depends on argparse >= 0.6.0 (0.7.1-1 installed)
      # luacheck 0.26.1-1 depends on luafilesystem >= 1.6.3 (1.8.0-1 installed)
      # luacheck 0.26.1-1 is now installed in ~/.local/share/luarocks (license: MIT)
      # ...
      ```

#### Rocks

- `luarocks install moonscript`
- `luarocks install moonpick`
- `luarocks install --server=https://luarocks.org/dev luaformatter`

[1]: https://neovim.io/
[2]: https://gitter.im/neovim/neovim
