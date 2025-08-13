#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1094,SC2139,SC2046,SC1090,SC2154,SC2155,SC2206,SC2012,SC1083,SC1091,SC2086,SC2034

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://github.com/jimeh/dotfiles/blob/main/zshenv

# profilling:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# tracing
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof
if [[ -n "$z_trace" ]]; then
  # Set a timestamp and script location in PS4 for better trace readability
  PS4=$'%D{%H:%M:%S} ${(%):-%N:%i}> ' # Adds timestamp, filename, and line number
  # Set logging output to a dedicated log file with a unique session ID
  exec 3>&2 2>>$HOME/.config/zsh/tmp/benchmark.$$.start.log
  setopt xtrace prompt_subst
fi

# z_debug=1 "$SHELL" -ilc exit
# Check if compinit is being called at the right time
# https://github.com/zimfw/zimfw/wiki/Troubleshooting#completion-is-not-working
if [[ -n "$z_debug" ]]; then
  autoload -Uz +X compinit
  functions[compinit]=$'print -u2 \'compinit being called at \'${funcfiletrace[1]}
  '${functions[compinit]}
fi

# Prevent system-wide RCS files from being sourced
# This ensures only our user configuration is loaded, preventing compinit conflicts
# Note: compinit override removed since we're using NO_RCS to prevent system-wide files from loading
setopt NO_RCS
setopt NO_MAILWARN
setopt NO_MAILWARNING
setopt NO_GLOBAL_RCS

# CRITICAL: Set these variables BEFORE any system files are sourced
# to prevent compinit from being called before ZIM can initialize it
export skip_global_compinit=1
export NO_GLOBAL_RCS=1
export MAILCHECK=0

# Set ZIM-specific environment variables to prevent premature compinit calls
export ZIM_DISABLE_AUTOLOAD=1

# Additional variables to prevent compinit from being called by other sources
export DEBIAN_PREVENT_KEYBOARD_CHANGES=1
export NVM_LAZY_LOAD=1
export NVM_COMPLETION=true

# Set ZDOTDIR based on the actual user's home directory
# This ensures it works correctly in containers where $HOME might be different
# Setup XDG and ZSH environment variables
# Export XDG variables with fallbacks
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_LOCAL_DIR=${XDG_LOCAL_DIR:-$HOME/.local}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$XDG_LOCAL_DIR/share}
export XDG_STATE_HOME=${XDG_STATE_HOME:-$XDG_LOCAL_DIR/state}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-${UID:-"${USER:-$(id -un)}"}}

if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || sudo mkdir -p "$XDG_RUNTIME_DIR" || {
    echo "⚠ Failed to create directory $XDG_RUNTIME_DIR"
  }
fi

declare perms owner
case "$(uname)" in
  Darwin)
    perms=$(stat -f "%Lp" "$XDG_RUNTIME_DIR" 2>/dev/null || echo "000")
    owner=$(stat -f "%u" "$XDG_RUNTIME_DIR" 2>/dev/null || echo "0")
    ;;
  Linux)
    perms=$(stat -c "%a" "$XDG_RUNTIME_DIR" 2>/dev/null || echo "000")
    owner=$(stat -c "%u" "$XDG_RUNTIME_DIR" 2>/dev/null || echo "0")
    ;;
esac

if [[ "$perms" != "700" ]]; then
  chmod 700 "$XDG_RUNTIME_DIR" 2>/dev/null || sudo chmod 700 "$XDG_RUNTIME_DIR" || {
    echo "⚠ Failed to set permissions on $XDG_RUNTIME_DIR"
  }
fi

if [[ "$owner" != "$UID" ]]; then
  USERNAME=${USERNAME:-$(id -un)}
  chown "$USERNAME" "$XDG_RUNTIME_DIR" 2>/dev/null || sudo chown "$USERNAME" "$XDG_RUNTIME_DIR" || {
    echo "⚠ Failed to change ownership of $XDG_RUNTIME_DIR"
  }
fi

# User directories
export XDG_DESKTOP_DIR=${XDG_DESKTOP_DIR:-$HOME/Desktop}
export XDG_DOWNLOAD_DIR=${XDG_DOWNLOAD_DIR:-$HOME/Downloads}
export XDG_DOCUMENTS_DIR=${XDG_DOCUMENTS_DIR:-$HOME/Documents}
export XDG_MUSIC_DIR=${XDG_MUSIC_DIR:-$HOME/Music}
export XDG_PICTURES_DIR=${XDG_PICTURES_DIR:-$HOME/Pictures}
export XDG_VIDEOS_DIR=${XDG_VIDEOS_DIR:-$HOME/Movies}
export XDG_PROJECTS_DIR=${XDG_PROJECTS_DIR:-$HOME/Projects}
export XDG_WORKSPACE_DIR=${XDG_WORKSPACE_DIR:-$HOME/Work}

export ZDOTDIR=$HOME/.config/zsh
export ZSH_DATA_DIR=${ZSH_DATA_DIR:-$XDG_DATA_HOME/zsh}
export ZSH_CACHE_DIR=${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}
export ZSH_COMPCACHE=${ZSH_COMPCACHE:-$ZSH_CACHE_DIR/compcache}
export ZDOTDIR_OPT=${ZDOTDIR_OPT:-$ZDOTDIR/opt}
export ZDOTDIR_ETC=${ZDOTDIR_ETC:-$ZDOTDIR/etc}

# ZSH state files
export ZSH_COMPDUMP=${ZSH_COMPDUMP:-$ZSH_COMPCACHE/.zcompdump}
export HISTFILE=${HISTFILE:-$ZSH_DATA_DIR/.zsh_history}
export ZIM_HOME=${ZIM_HOME:-$XDG_DATA_HOME/zim}

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

# if .zprofile exists, source it
if [[ $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
