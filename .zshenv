# shellcheck disable=SC1090,SC1091

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html

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

# ZSH https://wiki.archlinux.org/index.php/XDG_Base_Directory {
  export ZDOTDIR=~/.config/zsh
# }

# Only source this once
if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export MAILCHECK="30"
fi

# on interactive login shell
if [[ "$SHLVL" -eq 1 && ! -o LOGIN ]]; then
  if [ -f ~/.config/zsh/.zprofile ]; then
    . ~/.config/zsh/.zprofile
  fi
fi
