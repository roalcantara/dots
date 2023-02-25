# fuzzy find and execute alias
# https://github.com/thirteen37/fzf-alias/blob/main/fzf-alias.plugin.zsh
fzf_pick_alias() {
  local selection
  printf "💡 alias | fzf"
  if selection=$(alias | fzf --query="$BUFFER" | sed -re 's/=.+$/ /' | sed -re 's/=.+$/ /'); then
    BUFFER=$selection
    zle .accept-line
  fi
  zle redisplay
}
# ⌘ + a => ^[[97;9u
# ⌘ + ⌥ + a => ^[[97;11u
zle -N fzf_pick_alias
bindkey -M emacs '^[[97;11u' fzf_pick_alias
bindkey -M vicmd '^[[97;11u' fzf_pick_alias
bindkey -M viins '^[[97;11u' fzf_pick_alias
