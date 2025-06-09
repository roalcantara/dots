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

# Setup XDG and ZSH environment variables
if [ -x ~/.config/zsh/etc/functions/zsetup ]; then
  # Execute the script directly with arguments instead of sourcing
  source ~/.config/zsh/etc/functions/zsetup
fi

# Only source this once
if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export MAILCHECK="30"
fi

# if not macOS and profile exists, source it
if [[ "$OSTYPE" != "darwin"* && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
