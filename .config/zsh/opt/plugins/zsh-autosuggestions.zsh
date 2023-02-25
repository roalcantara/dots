# ZSH AUTOSUGGEST
# https://github.com/zsh-users/zsh-autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=magenta,bold'
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# ZSH AUTOSUGGEST
# https://github.com/zsh-users/zsh-autosuggestions
# Configure autosuggest to work properly with history substring search;
# without this, trying to history-substring-search with an empty line will hang zsh
ZSH_AUTOSUGGEST_CLEAR_WIDGETS=("${(@)ZSH_AUTOSUGGEST_CLEAR_WIDGETS:#(up|down)-line-or-history}")
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-substring-search-up history-substring-search-down)
