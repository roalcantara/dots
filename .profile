# shellcheck shell=bash disable=SC1090
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

# XDG USER DIRECTORIES https://wiki.archlinux.org/index.php/XDG_Base_Directory {
  # Where user-specific configurations should be written
  export XDG_CONFIG_HOME=~/.config # (analogous to /etc)
  # Where user-specific non-essential (cached) data should be written
  export XDG_CACHE_HOME=~/.cache # (analogous to /var/cache)
  # Where user-specific data files should be written
  export XDG_DATA_HOME=~/.local/share # (analogous to /usr/share).
  # Where user-specific state files should be written
  export XDG_STATE_HOME=~/.local/state # (analogous to /var/lib).
# }

# TASKWARRIOR {
  # Highly flexible command-line tool to manage TODO lists
  # https://taskwarrior.org/
  export TASK_WARRIOR_HOME=$XDG_CONFIG_HOME/tasks
  export TASKOPENRC=$TASK_WARRIOR_HOME/taskopenrc
  export TASKRC=$TASK_WARRIOR_HOME/taskrc
  export TASKDATA=$XDG_DATA_HOME/tasks/data
# }

# WAKATIME {
  export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
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

# set PATH so it includes user's private bin if it exists
if [ -d ~/.bin ]; then
  export PATH=~/.bin:$PATH
fi

# set PATH so it includes user's private bin if it exists
if [ -d ~/.local/bin ] ; then
  export PATH=~/.local/bin:$PATH
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  if [ -r ~/.dircolors ]; then
    eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  fi
fi