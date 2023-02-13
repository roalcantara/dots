# shellcheck shell=bash disable=SC2155,SC1090

# ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

export ZSH_VERSION="$(zsh --version | cut -d ' ' -f2)"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_DATA_DIR="$XDG_DATA_HOME/zsh"
export ZSH_COMPCACHE="$ZSH_CACHE_DIR/compcache"
export ZSH_COMPDUMP="$ZSH_COMPCACHE/.zcompdump"
export HISTFILE="$ZSH_DATA_DIR/.zsh_history"
