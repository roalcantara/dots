# shellcheck shell=bash disable=SC1090

# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc
# Contains commands that loads shell options, aliases, functions, key bindings and plugins

# Use viins keymap as the default.
bindkey -v

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# ZSH global aliases
# which are substituted anywhere on a line.
# It can be used to abbreviate frequently-typed usernames, hostnames, etc.
alias -g Chop='sed '\''s/.$//'\'''
alias -g G='| grep'
alias -g H='| head'
alias -g Inline='tr '\''\n'\'' '\'' '\'''
alias -g L='| less'
alias -g LTrim='sed -e '\''s/^[[:space:]]*//'\'''
alias -g M='| more'
alias -g RTrim='sed -e '\''s/ *$//g'\'''
alias -g T='| tail'
alias -g Trim='sed -e '\''s/^[[:space:]]*//'\'' -e '\''s/ *$//g'\'''
alias -g UUID='$(uuidgen | tr -d \n)'

# Named Directory Hashes
hash -d work="$HOME/Work"
hash -d docs="$HOME/Documents"
hash -d downloads="$HOME/Downloads"
