#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# Directory stack size
export DIRSTACKSIZE=100
export PAGER='less -FREXi'
export BROWSER='open'
export MANROFFOPT='-c'

# LESS {
  # https://linuxize.com/post/less-command-in-linux/
  export LESS='-RF'
  export LESS_HOME=$XDG_CONFIG_HOME/less
  export LESS_CACHE_HOME=$XDG_CACHE_HOME/less
  export LESSKEY=$LESS_CACHE_HOME/keys
  export LESSHISTFILE=$XDG_CACHE_HOME/history/lesshist
  export LESS_ADVANCED_PREPROCESSOR=1
# }

# COLORS {
  export CLICOLOR=1
  source $XDG_CONFIG_HOME/zsh/opt/plugins/theme-tokyonight-moon.zsh
# }

# HELPERS {
  # Redirects stdout (file descriptor 1) to /dev/null
  # Then redirects stderr (file descriptor 2) to wherever stdout is going (which is now /dev/null)
  # Works in all POSIX-compliant shells (sh, dash, bash, zsh, etc.)
  _has_command() {
    command -v "$1" >/dev/null 2>&1
  }
# }

# MISE {
  # A polyglot tool version manager. It replaces tools like asdf, nvm, pyenv, rbenv, etc.
  # https://mise.jdx.dev
  if [[ -e $XDG_DATA_HOME/mise/config.toml ]]; then
    export MISE_GLOBAL_CONFIG_FILE=$XDG_DATA_HOME/mise/config.toml
  fi

  if _has_command mise; then
    export MISE_CACHE_DIR=$XDG_CACHE_HOME/mise
    eval "$(mise activate zsh --yes --quiet --shims)"
  fi
# }

# HOMEBREW {
  # https://brew.sh
  # Determine Homebrew prefix based on OS and architecture
  if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$(if [[ -x /opt/homebrew/bin/brew ]]; then echo "/opt/homebrew"; elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then echo "/home/linuxbrew/.linuxbrew"; elif [[ -x /usr/local/bin/brew ]]; then echo "/usr/local"; else echo "/usr/local"; fi)}
    export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
    export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
    export HOMEBREW_NO_ENV_HINTS=1                # Hide hints
    export HOMEBREW_NO_ANALYTICS=1                # Disabled analytics
    export HOMEBREW_BAT=true                      # Use bat for the brew cat command
    export HOMEBREW_BAT_THEME=dracula             # Use this as the bat theme for syntax highlighting
    export HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1       # Don't dump vscode extensions
    export HOMEBREW_BUNDLE_FILE=${HOMEBREW_BUNDLE_FILE:-$XDG_CONFIG_HOME/homebrew/Brewfile} # https://docs.brew.sh/Manpage#bundle-subcommand
    eval "$("$HOMEBREW_BIN"/brew shellenv)"
  fi
# }

# TERM {
  if [ "$TERM_PROGRAM" = "ghostty" ]; then
    if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
      source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
    fi
    export SNACKS_GHOSTTY=true
  fi
  export TERM="${TERM:-xterm-256color}"
# }

if _has_command zsh; then
  export SHELL="$(which zsh)"
fi

if _has_command nvim; then
  export EDITOR=$(command -v nvim)
  export VIM_PATH=$XDG_CONFIG_HOME/nvim
  export MYVIMRC=$VIM_PATH/init.lua
  export NVIM_LOG_FILE=$XDG_CACHE_HOME/nvim/.nvimlog
  alias vim=nvim
  alias vi=nvim
else
  export EDITOR=$(command -v vim || command -v vi)
  alias vi=vim
fi

# EDITOR {
  export VISUAL=$EDITOR
  export SUDO_EDITOR=$EDITOR
  export GIT_EDITOR="$EDITOR -c 'startinsert'"
  export LAUNCH_EDITOR=$EDITOR
# }

if _has_command starship; then
  # STARSHIP | The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  # https://starship.rs/config/#configuration
  export STARSHIP_CONFIG_HOME=$XDG_CONFIG_HOME/starship
  export STARSHIP_CONFIG=$STARSHIP_CONFIG_HOME/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
fi

if _has_command gpg; then
  # GNUPG | The GNU Privacy Guard
  # https://gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
  # needed for git PGP-signed commits also needed for sops
  export GPG_TTY=$(tty)
  export GNUPGHOME=$XDG_CONFIG_HOME/gnupg
fi

if _has_command npm; then
  # NPM | Node Package Manager
  # https://docs.npmjs.com/cli/v7/commands/npm-config
  # https://docs.npmjs.com/cli/v7/configuring-npm/npmrc
  # `npm config list` => List all main npm settings
  # `npm config ls -l` => List all npm settings

  # Path to the personal npm configuration file
  # npm will read configuration from this file instead of the default location ($HOME/.npmrc)
  export npm_config_userconfig=$XDG_CONFIG_HOME/npm/npmrc

  # Path to npm's cache directory, which includes logs ($HOME/.npm)
  export npm_config_cache=$XDG_STATE_HOME/npm # $HOME/.local/state/npm

  # Set where global packages are installed when running `npm install -g [package]`.
  # Global binaries go to ${prefix}/bin and global packages to ${prefix}/lib/node_modules
  # export npm_config_prefix=${XDG_LOCAL_DIR}/npm

  # Opt out of update notifications https://npmjs.com/package/update-notifier#user-settings
  export NO_UPDATE_NOTIFIER=1

  # NODE REPL
  # https://nodejs.org/api/repl.html#repl_environment_variable_options
  export NODE_NO_WARNINGS=1 # silence all process warnings
fi

if _has_command luajit; then
  # LUA | Lua is a powerful, efficient, lightweight, embeddable scripting language
  # https://lua.org/manual/5.1/manual.html#5.4
  # https://nift.dev/docs/lua.html
  # 💡 luajit -e 'print(package.path)' luajit -e 'print(package.cpath)'
  export LUA_PATH="./?.lua;$HOMEBREW_SHARE/luajit-2.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;$HOMEBREW_SHARE/lua/5.1/?.lua;/$HOMEBREW_SHARE/lua/5.1/?/init.lua"
  export LUA_CPATH="./?.so;/usr/local/lib/lua/5.1/?.so;/opt/homebrew/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so"
fi

if _has_command gem; then
  # RubyGems | package manager for the Ruby programming language
  # https://guides.rubygems.org/command-reference/#gem-environment
  # 💡 gem env gempath
  export GEM_HOME=$HOMEBREW_PREFIX/opt/gems
fi

if _has_command cargo; then
  # CARGO | Rust package manager that downloads dependencies, compiles and distributes packages.
  # https://doc.rust-lang.org/cargo/guide/cargo-home.html
  export CARGO_HOME=$XDG_DATA_HOME/cargo
  export RUSTUP_HOME=$XDG_DATA_HOME/rustup
fi

if _has_command pnpm; then
  # PNPM | Fast, disk space efficient package manager
  # https://pnpm.io
  export PNPM_HOME=$XDG_DATA_HOME/pnpm # $HOME/.local/share/pnpm
fi

if _has_command jq; then
  # JQ | A lightweight and flexible command-line JSON processor
  # https://stedolan.github.io/jq/manual/#Advancedfeatures
  export JQ_COLORS='1;30:0;37:0;37:0;37:0;32:1;37:1;37'
fi

if _has_command rg; then
  # RIPGREP | A utility that combines the usability of The Silver Searcher with the raw speed of grep
  # https://github.com/BurntSushi/ripgrep
  export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/.ripgreprc
fi

if _has_command bat; then
  # BAT | A cat(1) clone with wings
  # https://github.com/sharkdp/bat#configuration-file
  export BAT_CONFIG_HOME=$XDG_CONFIG_HOME/bat
  export BAT_CONFIG_PATH=$BAT_CONFIG_HOME/bat.conf
fi

if _has_command glow; then
  # GLOW | A terminal-based markdown reader, renderer, and formatter
  # https://charm.sh/docs/glow
  export GLOW_CONFIG_PATH=$XDG_CONFIG_HOME/glow/conf.yml
fi

if _has_command gopass; then
  # GOPASS | The slightly more awesome standard unix password manager for teams
  # https://github.com/gopasspw/gopass/blob/master/docs/config.md
  export GOPASS_CONFIG_HOME=$XDG_CONFIG_HOME/gopass
  export GOPASS_CONFIG=$GOPASS_CONFIG_HOME/config
  export GOPASS_HOMEDIR=$HOME
  export PASSWORD_STORE_DIR=$XDG_DATA_HOME/gopass/password-store
  export PASSWORD_STORE_CLIP_TIME=45 #secs
  export PASSWORD_STORE_ENABLE_EXTENSIONS=true pass
fi

if _has_command gitlint; then
  # GITLINT | Path where gitlint looks for a config file
  # https://jorisroovers.com/gitlint/user_defined_rules
  export GITLINT_CONFIG=$XDG_CONFIG_HOME/gitlint/gitlint.cfg
fi

if _has_command wakatime-cli; then
  # WAKATIME | WakaTime command line interface
  # https://github.com/wakatime/wakatime#wakatime
  export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
fi
