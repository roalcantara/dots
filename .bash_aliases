#!/usr/bin/env bash

# ls aliases
alias ls='ls --color=auto'
alias l='ls -CF'
alias ll='ls -la'
alias lm='ll | "$PAGER"'
alias la='ls -A'
alias lr='ls -lrt'
alias lh='ls -lh'
alias lx='ls -X'
alias lk='ls -lSr'
alias lt='ls -ltr'
alias lc='ls -lcrt'
alias lu='ls -lur'
alias sl='l'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias count='find . -type f | wc -l'

# dotfiles
# https://atlassian.com/git/tutorials/dotfiles
alias d='/usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'