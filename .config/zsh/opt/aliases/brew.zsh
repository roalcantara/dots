# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# The Missing Package Manager for macOS (or Linux)
# https://brew.sh/
alias brs='brew services restart $(brew services list | tail -n +2 | fzf --ansi | cut -d" " -f1)'
alias bri="brew install"
alias brl='brew ls'
alias brc='brew --cache'
alias brcl='ls ~/Library/Caches/Homebrew'
alias brco='brew config'
alias brRepo='brew --repository'
alias brB='brew bundle --file ~/.config/brew/Brewfile'
alias brr='brew upgrade $(brew leaves | fzf --multi)'
alias brUp='brew upgrade $(brew outdated | fzf --multi)'
alias brUp!='brew autoremove && brew update && brew upgrade && brew upgrade --cask && brew cleanup && brew doctor'
alias brUpf!='git fetch "$(brew --repo)" && git -C "$(brew --repo)" reset --hard origin/master && brew update'
alias brD='brew bundle dump'
