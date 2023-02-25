# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# ASDF-DIRENV
# Direnv plugin for ASDF version manager
# https://github.com/asdf-community/asdf-direnv/blob/master/README.md#global-asdf-direnv-integration
# Undefine DIRENV_WATCHES (if it exists) so that direnv will reload the environment
alias reload='exec env -u DIRENV_WATCHES $SHELL'
