#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# Directory stack size
export DIRSTACKSIZE=${DIRSTACKSIZE:-100}
export PAGER=${PAGER:-"less -FREXi"}
export BROWSER=${BROWSER:-"open"}
export MANROFFOPT=${MANROFFOPT:-"-c"}

# LESS {
  # https://linuxize.com/post/less-command-in-linux/
  export LESS=${LESS:-"-RF"}
  export LESS_HOME=${LESS_HOME:-$XDG_CONFIG_HOME/less}
  export LESS_CACHE_HOME=${LESS_CACHE_HOME:-$XDG_CACHE_HOME/less}
  export LESSKEY=${LESSKEY:-$LESS_CACHE_HOME/keys}
  export LESSHISTFILE=${LESSHISTFILE:-$XDG_CACHE_HOME/history/lesshist}
  export LESS_ADVANCED_PREPROCESSOR=${LESS_ADVANCED_PREPROCESSOR:-1}
# }

# COLORS {
  export CLICOLOR=${CLICOLOR:-1}
  source ${ZDOTDIR:-$HOME/.config/zsh}/opt/plugins/theme-tokyonight-moon.zsh
# }

# HELPERS {
  # Redirects stdout (file descriptor 1) to /dev/null
  # Then redirects stderr (file descriptor 2) to wherever stdout is going (which is now /dev/null)
  # Works in all POSIX-compliant shells (sh, dash, bash, zsh, etc.)
  _has_command() {
    command -v "$1" >/dev/null 2>&1
  }
# }

# MISE | https://mise.jdx.dev {
  # A polyglot tool version manager. It replaces tools like asdf, nvm, pyenv, rbenv, etc.

  # Set the global configuration file path
  if [[ -e $XDG_DATA_HOME/mise/config.toml ]]; then
    export MISE_GLOBAL_CONFIG_FILE=${MISE_GLOBAL_CONFIG_FILE:-$XDG_DATA_HOME/mise/config.toml}
  fi

  # Set the cache directory path
  export MISE_CACHE_DIR=${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}

  # Activate mise if it is installed and load the shims
  if _has_command mise; then
    eval "$(mise activate zsh --yes --quiet --shims)"
  fi
# }

# HOMEBREW | https://brew.sh{
  # The missing package manager for macOS (and Linux)

  # Determine Homebrew environment variables based on OS and architecture and load it
  if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$(if [[ -x /opt/homebrew/bin/brew ]]; then echo "/opt/homebrew"; elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then echo "/home/linuxbrew/.linuxbrew"; elif [[ -x /usr/local/bin/brew ]]; then echo "/usr/local"; else echo "/usr/local"; fi)}
    export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
    export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
    export HOMEBREW_OPT=$HOMEBREW_PREFIX/opt
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

# SHELL {
  export SHELL=${SHELL:-"$(which zsh)"}
# }

# EDITOR {
  if _has_command nvim; then
    export EDITOR=${EDITOR:-"$(command -v nvim)"}
    export VIM_PATH=${VIM_PATH:-$XDG_CONFIG_HOME/nvim}
    export MYVIMRC=${MYVIMRC:-$VIM_PATH/init.lua}
    export NVIM_LOG_FILE=${NVIM_LOG_FILE:-$XDG_CACHE_HOME/nvim/.nvimlog}
    alias vim=nvim
    alias vi=nvim
  else
    export EDITOR=${EDITOR:-"$(command -v vim || command -v vi)"}
    alias vi=vim
  fi

  export VISUAL=${VISUAL:-$EDITOR}
  export SUDO_EDITOR=${SUDO_EDITOR:-$EDITOR}
  export GIT_EDITOR=${GIT_EDITOR:-"$EDITOR -c 'startinsert'"}
  export LAUNCH_EDITOR=${LAUNCH_EDITOR:-$EDITOR}
# }

# STARSHIP | https://starship.rs {
  # The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  # https://starship.rs/config/#configuration
  export STARSHIP_CONFIG_HOME=${STARSHIP_CONFIG_HOME:-$XDG_CONFIG_HOME/starship}
  export STARSHIP_CONFIG=${STARSHIP_CONFIG:-$STARSHIP_CONFIG_HOME/starship.toml}
  export STARSHIP_CACHE=${STARSHIP_CACHE:-$XDG_CACHE_HOME/starship}
# }

# GNUPG | https://gnupg.org {
  # The GNU Privacy Guard
  # Needed for git PGP-signed commits also needed for sops
  # https://gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
  export GPG_TTY=${GPG_TTY:="$(tty)"}
  export GNUPGHOME=${GNUPGHOME:-$XDG_CONFIG_HOME/gnupg}
# }

# NPM | https://docs.npmjs.com {
  # The Node Package Manager
  # `npm config list` => List all main npm settings
  # `npm config ls -l` => List all npm settings

  # Set where global packages are installed when running `npm install -g [package]`.
  # Global binaries go to ${prefix}/bin and global packages to ${prefix}/lib/node_modules
  export NPM_CONFIG_PREFIX=${NPM_CONFIG_PREFIX:-$XDG_DATA_HOME/npm}

  # Path to the personal npm configuration file
  # npm will read configuration from this file instead of the default location ($HOME/.npmrc)
  # https://docs.npmjs.com/cli/v7/configuring-npm/npmrc
  export NPM_CONFIG_USERCONFIG=${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/npmrc}

  # Path to npm's cache directory, which includes logs ($HOME/.npm)
  export NPM_CONFIG_CACHE=${NPM_CONFIG_CACHE:-$XDG_STATE_HOME/npm}

  # Opt out of update notifications https://npmjs.com/package/update-notifier#user-settings
  export NO_UPDATE_NOTIFIER=${NO_UPDATE_NOTIFIER:-1}

  # NODE REPL | https://nodejs.org/api/repl.html#repl_environment_variable_options
  export NODE_NO_WARNINGS=${NODE_NO_WARNINGS:-1} # silence all process warnings
# }

# RUBY | https://ruby-lang.org {

  # The Ruby Package Manager | 💡 gem env gempath
  # Configure the gem home directory
  # https://guides.rubygems.org/command-reference/#gem-environment
  export GEM_HOME=${GEM_HOME:-${HOMEBREW_OPT:-$XDG_DATA_HOME}/gems}

  # RBENV | The Ruby version manager
  # https://github.com/rbenv/rbenv
  export RBENV_ROOT=${RBENV_ROOT:-$XDG_DATA_HOME/rbenv}
# }

# GO | https://go.dev {
  # Configure the location of the Go workspace
  export GOPATH=${GOPATH:-$XDG_DATA_HOME/go}
# }

# LUA | https://lua.org {
  # Powerful, efficient, lightweight, embeddable scripting language
  # 💡 luajit -e 'print(package.path)' luajit -e 'print(package.cpath)'
  export LUA_PATH=${LUA_PATH:="./?.lua;$HOMEBREW_SHARE/luajit-2.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;$HOMEBREW_SHARE/lua/5.1/?.lua;/$HOMEBREW_SHARE/lua/5.1/?/init.lua"}
  export LUA_CPATH=${LUA_CPATH:="./?.so;/usr/local/lib/lua/5.1/?.so;/opt/homebrew/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so"}
# }

# CARGO | https://doc.rust-lang.org/cargo {
  # Rust package manager that downloads dependencies, compiles and distributes packages.

  # https://doc.rust-lang.org/cargo/guide/cargo-home.html
  export CARGO_HOME=${CARGO_HOME:-$XDG_DATA_HOME/cargo} # Set the cargo home directory
  export RUSTUP_HOME=${RUSTUP_HOME:-$XDG_DATA_HOME/rustup} # Set the rustup home directory
# }

# PNPM | https://pnpm.io {
  # Fast, disk space efficient package manager

  # Set the pnpm home directory
  export PNPM_HOME=${PNPM_HOME:-$XDG_DATA_HOME/pnpm}
# }

# JQ | https://stedolan.github.io/jq {
  # A lightweight and flexible command-line JSON processor

  # Set the jq colors
  # https://stedolan.github.io/jq/manual/#Advancedfeatures
  export JQ_COLORS=${JQ_COLORS:="1;30:0;37:0;37:0;37:0;32:1;37:1;37"}
# }

# RIPGREP | https://github.com/BurntSushi/ripgrep {
  # A utility that combines the usability of The Silver Searcher with the raw speed of grep

  # Set the ripgrep config path
  export RIPGREP_CONFIG_PATH=${RIPGREP_CONFIG_PATH:-$XDG_CONFIG_HOME/ripgrep/.ripgreprc}
# }

# BAT | https://github.com/sharkdp/bat {
  # A cat(1) clone with wings

  # Set the bat config path
  export BAT_CONFIG_HOME=${BAT_CONFIG_HOME:-$XDG_CONFIG_HOME/bat}
  export BAT_CONFIG_PATH=${BAT_CONFIG_PATH:-$BAT_CONFIG_HOME/bat.conf}
# }

# GLOW | https://charm.sh/docs/glow {
  # A terminal-based markdown reader, renderer, and formatter

  # Set the glow config path
  export GLOW_CONFIG_PATH=${GLOW_CONFIG_PATH:-$XDG_CONFIG_HOME/glow/conf.yml}
# }

# GOPASS | https://github.com/gopasspw/gopass {
  # The slightly more awesome standard unix password manager for teams

  # Set the gopass environment variables
  export GOPASS_CONFIG_HOME=${GOPASS_CONFIG_HOME:-$XDG_CONFIG_HOME/gopass}
  export GOPASS_CONFIG=${GOPASS_CONFIG:-$GOPASS_CONFIG_HOME/config}
  export GOPASS_HOMEDIR=${GOPASS_HOMEDIR:-$HOME}
  export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-$XDG_DATA_HOME/gopass/password-store}
  export PASSWORD_STORE_CLIP_TIME=${PASSWORD_STORE_CLIP_TIME:-45} #secs
  export PASSWORD_STORE_ENABLE_EXTENSIONS=${PASSWORD_STORE_ENABLE_EXTENSIONS:-true}
# }

# GITLINT | https://jorisroovers.com/gitlint {
  # Gitlint checks your commit messages for style and content

  # Set the gitlint config path
  export GITLINT_CONFIG=${GITLINT_CONFIG:-$XDG_CONFIG_HOME/gitlint/gitlint.cfg}
# }

# WAKATIME | https://github.com/wakatime/wakatime {
  # WakaTime command line interface

  # Set the wakatime config path
  export WAKATIME_HOME=${WAKATIME_HOME:-$XDG_CONFIG_HOME/wakatime}
# }
