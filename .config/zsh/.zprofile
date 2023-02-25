# shellcheck shell=bash disable=SC2155,SC1090

# ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# ZSH {
  export ZSH_VERSION="$(zsh --version | cut -d ' ' -f2)"
# }

# HOMEBREW {
  if type brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    export HOMEBREW_NO_ENV_HINTS=1
  fi
# }
