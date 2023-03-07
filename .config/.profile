# shellcheck shell=bash disable=SC1090,SC2155,SC1091
# https://gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Bash-Startup-Files

# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# Contains system-wide environment initialization
# Read and executed when Bash is invoked as an interactive login shell - unless if ~/.bash_profile or ~/.bash_login exists!
# https://linuxize.com/post/bashrc-vs-bash-profile

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=1000
export HISTFILESIZE=2000

# XDG USER DIRECTORIES {
  # Where user-specific configurations should be written
  # https://wiki.archlinux.org/index.php/XDG_Base_Directory
  export XDG_CONFIG_HOME=~/.config # (analogous to /etc)
  # Where user-specific non-essential (cached) data should be written
  export XDG_CACHE_HOME=~/.cache # (analogous to /var/cache)
  # Where user-specific data files should be written
  export XDG_DATA_HOME=~/.local/share # (analogous to /usr/share).
  # Where user-specific state files should be written
  export XDG_STATE_HOME=~/.local/state # (analogous to /var/lib).
# }

# WAKATIME {
  # WakaTime command line interface
  # https://github.com/wakatime/wakatime#wakatime
  export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
# }

# NVIM {
  # +BundleInstall +qall, Install all vim bundles
  # https://superuser.com/a/874924/389767
  if type nvim >/dev/null; then
    export EDITOR=$(which nvim)
    export VIM_PATH=$XDG_CONFIG_HOME/nvim
    export MYVIMRC=$VIM_PATH/init.lua
    export NVIM_LOG_FILE=$XDG_CACHE_HOME/nvim/.nvimlog
  else
    export EDITOR=$(command -v vim || command -v vi)
  fi
  alias vi='$EDITOR'
  alias vim='$EDITOR'
# }

# TERMINAL {
  if type kitty >/dev/null; then
    export KITTY_CONFIG_DIRECTORY=$XDG_CONFIG_HOME/kitty
    if [ -f /Applications/kitty.app/Contents/MacOS/kitty ]; then
      export TERMINAL=/Applications/kitty.app/Contents/MacOS/kitty
    elif [ -f /System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal ]; then
      export TERMINAL=/System/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal
    fi
  fi
# }

# GNUPG {
  # The GNU Privacy Guard
  # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
  if type gpg >/dev/null; then
    # needed for git PGP-signed commits
    # also needed for sops
    export GPG_TTY=$(tty)
  fi
# }

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # the default umask is set in /etc/profile; for setting the umask
  # for ssh logins, install and configure the libpam-umask package.
  #umask 022

  # include .bashrc if it exists
  if [ -f ~/.bashrc ]; then
    # Read by bash when interactive non-login shell is started
    # `--norc` file option inhibited this
    # `--rcfile` file option forces bash to read and execute commands from a given file - instead of ~/.bashrc
    . ~/.bashrc
  fi

  # don't put duplicate lines or lines starting with space in the history.
  # See bash(1) for more options
  HISTCONTROL=ignoreboth

  # make less more friendly for non-text input files, see lesspipe(1)
  if [ -x /usr/bin/lesspipe ]; then
    eval "$(SHELL=/bin/sh lesspipe)"
  fi
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# HOMEBREW {
  # The Missing Package Manager for macOS (or Linux)
  # https://brew.sh
  if [[ "$OSTYPE" == *darwin* ]]; then
    export HOMEBREW_PREFIX=/usr/local
  else
    export HOMEBREW_PREFIX=~/.linuxbrew
    eval "$($HOMEBREW_PREFIX/bin/brew shellenv)"
  fi

  if test -e $HOMEBREW_PREFIX/bin/brew; then
    export HOMEBREW_NO_ENV_HINTS=1                                  # Hide hints
    export HOMEBREW_NO_ANALYTICS=1                                  # Disabled analytics
    export HOMEBREW_BUNDLE_FILE=$XDG_CONFIG_HOME/script/Brewfile    # https://homebrew-file.readthedocs.io/en/latest/usage.html
  fi
# }

# PATH {
  export -a path=(
    # set PATH so it includes user's private bin if it exists
    "${XDG_CONFIG_HOME}"/bin
    /usr/local/{bin,sbin}
    "${HOMEBREW_PREFIX}"/{bin,sbin}
    "${path[@]}"
  )
# }

# FPATH {
  export -a fpath=(
    "${fpath[@]}"
  )
# }

# CDPATH {
  export -a cdpath=(
    "${HOME}"
    "${XDG_CONFIG_HOME}"
    "${VIM_PATH}"
    "${cdpath[@]}"
  )
# }

# MANPATH {
  export -a manpath=(
    "${manpath[@]}"
  )
# }
