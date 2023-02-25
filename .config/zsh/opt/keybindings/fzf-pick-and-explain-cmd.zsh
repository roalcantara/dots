# fuzzy find and explain a command from history
# https://explainshell.com
# https://linuxhint.com/search-in-my-zsh-history
fzf_pick_and_explain_cmd() {
  printf "💡 explainsh" && explainsh && zle reset-prompt
}

# ⌘ + e => ^[[101;9u
# ⌘ + ⌥ + e => ^[[101;11u
zle -N fzf_pick_and_explain_cmd
bindkey -M emacs '^[[101;11u' fzf_pick_and_explain_cmd
bindkey -M vicmd '^[[101;11u' fzf_pick_and_explain_cmd
bindkey -M viins '^[[101;11u' fzf_pick_and_explain_cmd
