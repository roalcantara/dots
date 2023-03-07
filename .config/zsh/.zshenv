# shellcheck disable=SC1090,SC1091,SC2086,SC2155

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html

# Only source this once
if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export MAILCHECK="30"
fi

# system-wide initialization
if [[ -e ~/.profile ]]; then
  . ~/.profile
fi

# ZSH {
  export ZDOTDIR=$XDG_CONFIG_HOME/zsh
  export ZSH_DATA_DIR=$XDG_DATA_HOME/zsh
  export ZSH_CACHE_DIR=$XDG_CACHE_HOME/zsh
  export ZSH_COMPCACHE=$ZSH_CACHE_DIR/compcache
  export ZSH_COMPDUMP=$ZSH_COMPCACHE/.zcompdump
  export HISTFILE=$ZSH_DATA_DIR/.zsh_history
  export SHELL=$(which zsh)
# }

# on interactive login shell
if [[ "$SHLVL" -eq 1 && ! -o LOGIN ]]; then
  if [ -f ~/.config/zsh/.zprofile ]; then
    . ~/.config/zsh/.zprofile
  fi
fi
