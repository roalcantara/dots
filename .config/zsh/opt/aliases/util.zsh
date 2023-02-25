# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# PS
alias ps!='/bin/ps'
alias ps='PID=$(grc ps -afxAcmo user,pmem | fzf --multi --ansi --header-lines=1 --preview "grc ps o args {2}; grc ps mu {2}") && test ! -z "$PID" && echo "$PID" | awk "{print $2}" | xargs -r kill -9'

# HTOP {
# Improved top (interactive process viewer)
# https://htop.dev
if (( $+commands[htop] )); then
  alias top!=$(which top)
  alias top=htop
fi
# }

# BAT {
# A cat(1) clone with wings
# https://github.com/sharkdp/bat#configuration-file
if (( $+commands[bat] )); then
  export LESS='-RF'
  export BAT_PAGER="${PAGER}"
  alias cat!='$(which cat)'
  alias cat=bat
fi

# Read system manual pages (man) using bat as the manual page formatter.
# https://github.com/eth-p/bat-extras/blob/master/doc/batman.md
if (( $+commands[batman] )); then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias man!='$(which man)'
  alias man='batman'
fi

# Kubernets
# Short alias to set/show context/namespace (only works for bash and bash-compatible shells, current context to be set before using kn to set namespace)
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-context-and-configuration
if (( $+commands[kubectl] )); then
  alias k=kubectl
  alias kx='f() { [ "$1" ] && kubectl config use-context $1 || kubectl config current-context ; } ; f'
  alias kn='f() { [ "$1" ] && kubectl config set-context --current --namespace $1 || kubectl config view --minify | grep namespace | cut -d" " -f6 ; } ; f'
fi

# n³ the unorthodox terminal file manager
# https://github.com/jarun/nnn
if (( $+commands[nnn] )); then
  # -n      type-to-nav mode
  # -A      no dir auto-enter in type-to-nav
  # -i      show current file info
  # -d      detail mode
  # -D      dirs in context color
  # -H      show hidden files
  # -o      open files only on Enter
  # -c      cli-only NNN_OPENER (trumps -e)
  # -Q      no quit confirmation
  alias nnn='nnn -n -A -i -d -H -o -c -Q'
fi
