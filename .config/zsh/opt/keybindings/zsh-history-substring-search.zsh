# https://github.com/zsh-users/zsh-history-substring-search
# ZSH port of Fish history search (up arrow)

bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down

zle -N history-substring-search-up; zle -N history-substring-search-down
