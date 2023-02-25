# fuzzy find and execute a task from a Makefile from the current directory
fzf_pick_make_task() {
  local selection=$(mk)
  if [ -n "${selection}" ]; then
    BUFFER=$selection
    zle .accept-line
    zle redisplay
  fi
}

# ⌥ + m => ^[m
# ⌘ + ⌥ + m => ^[[109;11u
zle -N fzf_pick_make_task
bindkey -M emacs '^[[109;11u' fzf_pick_make_task
bindkey -M vicmd '^[[109;11u' fzf_pick_make_task
bindkey -M viins '^[[109;11u' fzf_pick_make_task
