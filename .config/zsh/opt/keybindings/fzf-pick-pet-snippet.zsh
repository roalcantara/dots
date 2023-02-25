# Register the previous command
# https://github.com/knqyf263/pet#zsh-prev-function
function prev() {
  PREV=$(fc -lrn | head -n 1)
  sh -c "pet new `printf %q "$PREV"`"
}

# Fuzzy find and execute snippet
# https://github.com/knqyf263/pet#zsh
fzf_pick_pet_snippet_widget() {
  BUFFER=$(pet search --color --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle .accept-line
  zle redisplay
}

# ⌘ + ⌥ + / - Pick a Pet snippet and execute it
zle     -N    fzf_pick_pet_snippet_widget
stty -ixon
bindkey -M    emacs '^[[47;11u' fzf_pick_pet_snippet_widget
bindkey -M    vicmd '^[[47;11u' fzf_pick_pet_snippet_widget
bindkey -M    viins '^[[47;11u' fzf_pick_pet_snippet_widget
