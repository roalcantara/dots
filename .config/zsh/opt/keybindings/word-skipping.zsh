# keybindings
# While for normal editing a single keymap is used exclusively,
# in many modes a local keymap allows for some keys to be customised.
# For example, in an incremental search mode, a binding in the isearch keymap
# will override a binding in the main keymap but all keys that are not overridden
# can still be used.
# http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Local-Keymaps
# https://tjay.dev/howto-my-terminal-shell-setup-hyper-js-zsh-starship/
# https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/lib/completion.zsh

# [shift+left] skipping-word-backward
bindkey '^[[1;2D' backward-word
# [shift+right] skipping-word-forward
bindkey '^[[1;2C' forward-word
