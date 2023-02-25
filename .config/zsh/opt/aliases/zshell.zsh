# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# Reload zshrc
alias zload='source ~/.zshenv && source ~/.zshrc'

# suffix: allows to open specific programs for files
# that are typed into the command line depending on their extensions
# e.g.: ❯ file.pdf # open file.pdf on PDF viewer in background
alias -s {pdf,PDF}='background mupdf'
alias -s {htm,html,HTM,HTML}='background brave'
alias -s {mp4,MP4,mov,MOV}='background vlc'
alias -s {zip,ZIP}='unzip -l'
alias -s {tar,TAR}='tar -xvf'

# Grep history
alias hgrep='fc -Dlim "*$@*" 1'
