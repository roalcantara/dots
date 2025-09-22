#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1094,SC2139,SC2046,SC1090,SC2154,SC2155,SC2206,SC2012,SC1083,SC1091,SC2086,SC2034

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# zsh --sourcetrace: Show full path of sourced files
# http://zsh.sourceforge.net/Intro/intro_3.html | https://github.com/jimeh/dotfiles/blob/main/zshenv

## 🔖 PROFILING/TRACING/DEBUGGING {
# To enable profilling run:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# To enable tracing run:
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof
if [[ -n "$z_trace" ]]; then
  # Set a timestamp and script location in PS4 for better trace readability
  PS4=$'%D{%H:%M:%S} ${(%):-%N:%i}> ' # Adds timestamp, filename, & line number
  # Set logging output to a dedicated log file with a unique session ID
  exec 3>&2 2>>$HOME/.config/zsh/tmp/benchmark.$$.start.log
  setopt xtrace prompt_subst
fi

# To enable debugging run:
#   z_debug=1 "$SHELL" -ilc exit
# Check if compinit is being called at the right time
# https://github.com/zimfw/zimfw/wiki/Troubleshooting#completion-is-not-working
if [[ -n "$z_debug" ]]; then
  autoload -Uz +X compinit
  functions[compinit]=$'print -u2 \'compinit being called at \'${funcfiletrace[1]}
  '${functions[compinit]}
fi
# }

## 🌐 i18n {
# The values that the environment variables may be assigned are not restricted;
# Environment and argument space is limited by {ARG_MAX}.
# Avoid conflicts with commonly exported environment variables.
# https://pubs.opengroup.org/onlinepubs/7908799/xbd/envvar.html
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_COLLATE=C
# }

## 🔒 PREVENT COMPIINIT CALLS {
# Set these variables BEFORE any system files are sourced (e.g. NO_RCS)
# It prevents compinit from being called by other sources
export skip_global_compinit=1
export NO_GLOBAL_RCS=1
export MAILCHECK=0
export ZIM_DISABLE_AUTOLOAD=1
export DEBIAN_PREVENT_KEYBOARD_CHANGES=1
export NVM_LAZY_LOAD=1
export NVM_COMPLETION=true
# }

## 🔒 PREVENT SYSTEM-WIDE RCS FILES FROM BEING SOURCED {
# 💡 compinit override removed; NO_RCS prevents system-wide files from loading
# It ensures only our user config is loaded, preventing compinit conflicts
setopt NO_RCS
setopt NO_MAILWARN
setopt NO_MAILWARNING
setopt NO_GLOBAL_RCS
# }

## 🚀 XDG|ZSH ENVIRONMENT SETUP & OPTIMIZATION {
# ⚡️ XDG ENVIRONMENT SETUP - Smart caching system for BLAZING FAST shell startup
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_RUNTIME_DIR=/tmp/runtime-$UID
export XDG_LOCAL_DIR=$HOME/.local
export XDG_LOCAL_BIN_DIR=$HOME/.local/bin
export XDG_PROJECTS_DIR=$HOME/Projects
export XDG_WORKSPACE_DIR=$HOME/Work
export XDG_DESKTOP_DIR=$HOME/Desktop
export XDG_DOWNLOAD_DIR=$HOME/Downloads
export XDG_TEMPLATES_DIR=$HOME/Templates
export XDG_PUBLICSHARE_DIR=$HOME/Public
export XDG_DOCUMENTS_DIR=$HOME/Documents
export XDG_MUSIC_DIR=$HOME/Music
export XDG_PICTURES_DIR=$HOME/Pictures
export XDG_VIDEOS_DIR=$HOME/Movies
export ZDOTDIR=$HOME/.config/zsh
export ZSH_DATA_DIR=$HOME/.local/share/zsh
export HISTFILE=$HOME/.local/share/zsh/.zsh_history
export ZSH_CACHE_DIR=$HOME/.cache/zsh
export ZSH_COMPCACHE=$HOME/.cache/zsh/compcache
export ZSH_COMPDUMP=$HOME/.cache/zsh/compcache/.zcompdump
export zdumpfile=$HOME/.cache/zsh/compcache/.zcompdump
export ZDOTDIR_ETC=$HOME/.config/zsh/etc
export ZDOTDIR_OPT=$HOME/.config/zsh/opt
export ZIM_HOME=$HOME/.local/share/zim
# }

# if .zprofile exists, source it (after XDG setup so ZDOTDIR is available)
if [[ $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
