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

# MISE {
if [[ -e $XDG_DATA_HOME/mise/config.toml ]]; then
  export MISE_GLOBAL_CONFIG_FILE=$XDG_DATA_HOME/mise/config.toml
fi

if (($ + commands[mise])); then
  eval "$(mise activate zsh --yes --quiet --shims)"
fi
# }

# HOMEBREW {
# https://brew.sh
# Determine Homebrew prefix based on OS and architecture
if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:=${HOMEBREW_PREFIX:-$(if [ -d /opt/homebrew ]; then echo "/opt/homebrew"; elif [ -d /home/linuxbrew/.linuxbrew ]; then echo "/home/linuxbrew/.linuxbrew"; else echo "/usr/local"; fi)}}
  export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
  export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
  export HOMEBREW_NO_ENV_HINTS=1                                 # Hide hints
  export HOMEBREW_NO_ANALYTICS=1                                 # Disabled analytics
  export HOMEBREW_BAT=true                                       # Use bat for the brew cat command
  export HOMEBREW_BAT_THEME=dracula                              # Use this as the bat theme for syntax highlighting
  export HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1                        # Don't dump vscode extensions
  export HOMEBREW_BUNDLE_FILE=$XDG_CONFIG_HOME/homebrew/Brewfile # https://docs.brew.sh/Manpage#bundle-subcommand
  eval "$("$HOMEBREW_BIN"/brew shellenv)"
fi
# }
