# fuzzy find and execute executable
# https://github.com/knqyf263/pet
fzf_pick_bin() {
  puts "aid && zle reset-prompt" -x
}

# ⌘ ⌥ .
zle -N fzf_pick_bin
bindkey -M emacs '^[[46;11u' fzf_pick_bin
bindkey -M vicmd '^[[46;11u' fzf_pick_bin
bindkey -M viins '^[[46;11u' fzf_pick_bin
