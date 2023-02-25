# Fuzzy find and copy a Pet snippet to the clipboard
# https://github.com/knqyf263/pet
fzf_pick_pet_snippet_and_copy_it() {
  pet search --color | pbcopy
}

# ⌘ + ⌥ + ⇧ + /
zle -N fzf_pick_pet_snippet_and_copy_it
stty -ixon
bindkey -M emacs '^[[47;12u' fzf_pick_pet_snippet_and_copy_it
bindkey -M vicmd '^[[47;12u' fzf_pick_pet_snippet_and_copy_it
bindkey -M viins '^[[47;12u' fzf_pick_pet_snippet_and_copy_it
