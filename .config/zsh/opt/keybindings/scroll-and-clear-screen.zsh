scroll-and-clear-screen() {
  printf '\n%.0s' {1..$LINES}
  zle clear-screen
}
zle -N scroll-and-clear-screen
bindkey '^l' scroll-and-clear-screen