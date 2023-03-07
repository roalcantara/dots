# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# The Missing Package Manager for macOS (or Linux)
# https://brew.sh/
alias brs='brew services restart $(brew services list | tail -n +2 | fzf --ansi | cut -d" " -f1)'
alias brb='brew bundle --file ~/.config/brew/Brewfile'
alias bru='brew upgrade $(brew leaves | fzf --multi)'
alias bru!='brew upgrade $(brew outdated | fzf --multi)'
