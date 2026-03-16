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

# Load XDG environment variables from .profile
if [ -f $HOME/.profile ]; then
  source $HOME/.profile
fi

# if .zprofile exists, source it (after XDG setup so ZDOTDIR is available)
if [[ $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
