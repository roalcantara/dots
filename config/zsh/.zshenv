#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1094,SC2139,SC2046,SC1090,SC2154,SC2155,SC2206,SC2012,SC1083,SC1091,SC2086,SC2034

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://github.com/jimeh/dotfiles/blob/main/zshenv

# Ensure compinit is NOT loaded before Zinit loads in ~/zshrc.
skip_global_compinit=1
NO_GLOBAL_RCS=1

# profilling:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# tracing
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof
if [[ -n "$z_trace" ]]; then
  # Set a timestamp and script location in PS4 for better trace readability
  PS4=$'%D{%H:%M:%S} ${(%):-%N:%i}> ' # Adds timestamp, filename, and line number
  # Set logging output to a dedicated log file with a unique session ID
  exec 3>&2 2>>$HOME/.config/zsh/tmp/benchmark.$$.start.log
  setopt xtrace prompt_subst
fi

## INTERNATIONALISATION VARIABLES {
# The values that the environment variables may be assigned are not restricted;
# Except that they are considered to end with a null byte and the total space used to store the environment and the arguments to the process is limited to {ARG_MAX} bytes.
# It is unwise to conflict with certain variables that are frequently exported by widely used command interpreters and applications.
# https://pubs.opengroup.org/onlinepubs/7908799/xbd/envvar.html
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_COLLATE=C
# }

setup_xdg_and_zsh() {
  local -A XDG_DIRS=(
    [XDG_BIN_HOME]="$HOME/.local/bin"
    [XDG_PROJECTS_DIR]="$HOME/Projects"
    [XDG_WORKSPACE_DIR]="$HOME/Work"
    [XDG_CONFIG_HOME]="$HOME/.config"
    [XDG_CACHE_HOME]="$HOME/.cache"
    [XDG_DATA_HOME]="$HOME/.local/share"
    [XDG_STATE_HOME]="$HOME/.local/state"
    [XDG_RUNTIME_DIR]="/tmp/runtime-$USER"
    [XDG_DESKTOP_DIR]="$HOME/Desktop"
    [XDG_DOWNLOAD_DIR]="$HOME/Downloads"
    [XDG_DOCUMENTS_DIR]="$HOME/Documents"
    [XDG_MUSIC_DIR]="$HOME/Music"
    [XDG_PICTURES_DIR]="$HOME/Pictures"
    [XDG_VIDEOS_DIR]="$HOME/Movies"
  )
  local -A ZSH_DIRS=(
    [ZDOTDIR]="$XDG_CONFIG_HOME/zsh"
    [ZSH_DATA_DIR]="${XDG_DIRS[XDG_DATA_HOME]}/zsh"
    [ZSH_CACHE_DIR]="${XDG_DIRS[XDG_CACHE_HOME]}/zsh"
    [ZSH_COMPCACHE]="${XDG_DIRS[XDG_CACHE_HOME]}/zsh/compcache"
    [ZSH_TMP_DIR]="$XDG_CONFIG_HOME/zsh/tmp"
    [ZIM_HOME]="${XDG_DIRS[XDG_DATA_HOME]}/zim"
  )
  local -A ZSH_OPTS=(
    [ZSH_VERSION]="5.9" # zsh --version | cut -d ' ' -f2
    [ZDOTDIR_OPT]="$XDG_CONFIG_HOME/zsh/opt"
    [ZDOTDIR_ETC]="$XDG_CONFIG_HOME/zsh/etc"
    [HISTFILE]="${ZSH_DIRS[ZSH_DATA_DIR]}/.zsh_history"
    [ZSH_COMPDUMP]="${ZSH_DIRS[ZSH_COMPCACHE]}/.zcompdump"
  )
  _ensure_permissions() {
    local perms=$(stat -f "%Lp" $XDG_RUNTIME_DIR)
    if [[ $perms != "700" ]]; then
      sudo chmod 700 $XDG_RUNTIME_DIR || {
        echo "Failed to set permissions '700' to XDG_RUNTIME_DIR: '$XDG_RUNTIME_DIR' for '$USER' (UID: $UID).."
        return 1
      }
    fi

    local owner=$(stat -f "%u" $XDG_RUNTIME_DIR)
    if [[ $owner != "$UID" ]]; then
      sudo chown $USER $XDG_RUNTIME_DIR || {
        echo "Failed to change ownership of XDG_RUNTIME_DIR: '$XDG_RUNTIME_DIR' for '$USER' (UID: $UID).."
        return 1
      }
    fi
  }
  _setup_xdg() {
    # Fallback to default XDG paths
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$USER}"

    # XDG User directories
    export XDG_DESKTOP_DIR="${XDG_DESKTOP_DIR:-$HOME/Desktop}"
    export XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
    export XDG_DOCUMENTS_DIR="${XDG_DOCUMENTS_DIR:-$HOME/Documents}"
    export XDG_MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
    export XDG_PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
    export XDG_VIDEOS_DIR="${XDG_VIDEOS_DIR:-$HOME/Movies}"
    export XDG_PROJECTS_DIR="${XDG_PROJECTS_DIR:-$HOME/Projects}"
    export XDG_WORKSPACE_DIR="${XDG_WORKSPACE_DIR:-$HOME/Work}"

    # Create directories if they don't exist
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_DESKTOP_DIR" "$XDG_DOWNLOAD_DIR" "$XDG_DOCUMENTS_DIR" "$XDG_MUSIC_DIR" "$XDG_PICTURES_DIR" "$XDG_VIDEOS_DIR" "$XDG_PROJECTS_DIR" "$XDG_WORKSPACE_DIR" "$XDG_RUNTIME_DIR"
  }
  _setup_zsh() {
    # ZSH directories
    export ZDOTDIR="${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}"
    export ZSH_DATA_DIR="${ZSH_DATA_DIR:-$XDG_DATA_HOME/zsh}"
    export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"
    export ZSH_COMPCACHE="${ZSH_COMPCACHE:-$ZSH_CACHE_DIR/compcache}"

    # ZSH custom directories
    export ZDOTDIR_OPT="${ZDOTDIR_OPT:-$ZDOTDIR/opt}"
    export ZDOTDIR_ETC="${ZDOTDIR_ETC:-$ZDOTDIR/etc}"

    # ZSH state files
    export ZSH_COMPDUMP="${ZSH_COMPDUMP:-$ZSH_COMPCACHE/.zcompdump}"
    export HISTFILE="${HISTFILE:-$ZSH_DATA_DIR/.zsh_history}"

    # Create directories if they don't exist
    mkdir -p "$ZDOTDIR" "$ZSH_DATA_DIR" "$ZSH_CACHE_DIR" "$ZSH_COMPCACHE"
  }
  _setup_xdg
  _ensure_permissions
  _setup_zsh
}

# Setup XDG and ZSH environment variables
setup_xdg_and_zsh

# Only source this once
if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export MAILCHECK="30"
fi

# if not macOS and profile exists, source it
if [[ "$OSTYPE" != "darwin"* && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
