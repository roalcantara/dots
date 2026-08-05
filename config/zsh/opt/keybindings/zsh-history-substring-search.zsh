# zsh-history-substring-search
# https://coderwall.com/p/jpj_6q/zsh-better-history-searching-with-arrow-keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

# Load terminfo module
zmodload -F zsh/terminfo +p:terminfo
# Plugin is skipped in ZSH_MINIMAL_TERMINAL; only bind when widgets exist.
if (( ${+widgets[history-substring-search-up]} )); then
  for key ('^P' ${terminfo[kcuu1]}) bindkey ${key} history-substring-search-up
  for key ('^N' ${terminfo[kcud1]}) bindkey ${key} history-substring-search-down
fi
unset key
