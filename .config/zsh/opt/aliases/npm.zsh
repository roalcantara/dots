# Useful Alias for ZSH
# https://dev.to/equiman/useful-alias-for-zsh-1j8b

alias npr='rm -rf dist temp tmp build node_modules'
alias npr!='rm -rf dist temp tmp build coverage node_modules package-lock.json && npm i'

alias nls='npm list -g --depth 0'

alias ni='npm i'
alias nis='npm i -S '
alias nid='npm i -D '

alias nb='npm run build'
alias ns='npm run start'
alias nt='npm run test'
alias ne='npm run e2e'
alias nrc='npm run clean'
alias nba='npm run build:all'
alias nbd='npm run build:dev'
alias nbp='npm run build:prod'
alias nsd='npm run start:dev'
alias nsp='npm run start:prod'
alias nta='npm run test:all'
alias nea='npm run e2e:all'
alias nli='npm run lint'
alias nla='npm run lint:all'
alias nrx='rm package-lock.json && npm cache clean --force && rm -rf node_modules && npm i'
