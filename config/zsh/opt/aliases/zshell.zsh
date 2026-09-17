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

# Similar to opt-shellAliases, but are substituted anywhere on a line.;
# These do not have to be at the beginning of the command line
alias -g LTrim="sed -e 's/^[[:space:]]*//'";
alias -g RTrim="sed -e 's/ *$//g'";
alias -g Trim="sed -e 's/^[[:space:]]*//' -e 's/ *$//g'";
alias -g Inline="tr '\\n' ' '";

# Returns a new String with the last character removed.
# If the string ends with rn, both characters are removed.
# Applying chop to an empty string returns an empty string.
# String#chomp is often a safer alternative, as it leaves the string unchanged
# if it doesn’t end in a record separator - https://bit.ly/3xIElkJ
alias -g Chop="sed 's/.$//'";
