# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc
# Contains commands that loads shell options, aliases, functions, key bindings and plugins
# shellcheck shell=bash disable=SC1090

# keep at the top
[ -x ~/.local/bin/fig ] && eval "$(~/.local/bin/fig init zsh pre --rcfile zshrc)"

source ~/.config/zsh/etc/prepare.zsh    # tooling, options & autoload
source_file ~/.config/.login
source_file ~/.config/zsh/etc/setup.zsh # compile, profilling & cleanup

# Fig post block. Keep at the bottom of this file.
[ -x ~/.local/bin/fig ] && smartcache eval ~/.local/bin/fig init zsh post --rcfile zshrc
