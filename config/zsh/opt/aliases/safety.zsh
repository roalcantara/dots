# Gomi {
# `rm` sends files to a restorable trash instead of deleting them.
# The real rm is `\rm` or `command rm`; scripts and `zsh -c` keep it.
# https://gomi.dev
if (( $+commands[gomi] )); then
  alias rm='gomi'
fi
# }
