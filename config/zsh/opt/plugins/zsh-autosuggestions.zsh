# ZSH_HIGHLIGHT
export ZSH_HIGHLIGHT_IGNORE=("${(@)ZSH_HIGHLIGHT_IGNORE:#grc}")

# ZSH AUTOSUGGEST (ZSH v4.3.11 or later)
# https://github.com/zsh-users/zsh-autosuggestions
# Fish-like fast/unobtrusive autosuggestions for zsh.
# It suggests commands as you type based on history and completions.

## ZSH_AUTOSUGGEST KEYBINDINGS (https://bit.ly/3DTvODm)
# This plugin provides a few widgets that you can use with `bindkey`:

# autosuggest-accept    :Accepts the current suggestion.
# autosuggest-execute   :Accepts and executes the current suggestion.
# autosuggest-clear     :Clears the current suggestion.
# autosuggest-fetch     :Fetches a suggestion (works even when suggestions are disabled).
# autosuggest-disable   :Disables suggestions.
# autosuggest-enable    :Re-enables suggestions.
# autosuggest-toggle    :Toggles between enabled/disabled suggestions.
#
# For example, this would bind <kbd>ctrl</kbd> + <kbd>space</kbd> to accept the current suggestion.
#
# ```sh
# bindkey '^ ' autosuggest-accept
# ```

export ZSH_AUTOSUGGEST_STRATEGY=(history completion)           # SUGGESTION STRATEGY (https://bit.ly/4adKbyi)
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=magenta,bold'       # HIGHLIGHT STYLE https://bit.ly/3C8Yk3o)
export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20                      # MAX SIZE OF THE BUFFER (https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file#disabling-suggestion-for-large-buffers)
export ZSH_AUTOSUGGEST_USE_ASYNC=true                          # SUGGESTIONS ARE FETCHED ASYNCHRONOUSLY BY DEFAULT IN ZSH VERSIONS 5.0.8 AND GREATER (https://github.com/zsh-users/zsh-autosuggestions?tab=readme-ov-file#asynchronous-mode)

## ZSH_AUTOSUGGEST WIDGETS MAPPING (https://bit.ly/4fYswfr)
## This plugin works by triggering custom behavior when certain zle widgets are invoked. You can add and remove widgets from these arrays to change the behavior of this plugin.

### ZSH_AUTOSUGGEST_CLEAR_WIDGETS (https://bit.ly/4fXN87E) - WIDGETS IN THIS ARRAY WILL CLEAR THE SUGGESTION WHEN INVOKED:
# accept-line                                     : Executes current command line when pressing [Enter]
# copy-earlier-word                               : Copies word from previous command with [Alt+.]
# down-line-or-beginning-search                   : Moves ↓ history matching current prefix [↓]
# down-line-or-history                            : Press ↓ to browse your command history? This keeps suggestions from popping up while you're looking through past commands! No suggestions interfering while you browse through recent commands
# history-beginning-search-backward               : Searches history backward from line start [Ctrl+P]
# history-beginning-search-backward-end           : Like above but places cursor at end [Ctrl+P]
# history-beginning-search-forward                : Searches history forward from line start [Ctrl+N]
# history-beginning-search-forward-end            : Like above but places cursor at end [Ctrl+N]
# history-search-backward                         : Searches history backward from cursor [Ctrl+R]
# history-search-forward                          : Searches history forward from cursor [Ctrl+S]
# history-substring-search-down                   : Searches substring anywhere in history [↓]
# history-substring-search-up                     : Searches substring anywhere in history [↑]
# up-line-or-beginning-search                     : Moves ↑ history matching current prefix [↑]
# up-line-or-history                              : Press ↑ to browse your command history? This keeps suggestions from popping up while you're looking through past commands! No suggestions interfering while you browse through recent commands
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
  bracketed-paste
  expand-or-complete
  push-line-or-edit
  up-line-or-search
  down-line-or-search
)

### ZSH_AUTOSUGGEST_ACCEPT_WIDGETS (https://bit.ly/4fUeXNV) - WIDGETS IN THIS ARRAY WILL ACCEPT THE SUGGESTION WHEN INVOKED:
# forward-char                                    : Press → to accept suggestion one character at a time. Like typing it yourself, but faster!
# end-of-line                                     : Hit END key to accept the full suggestion in one go. Perfect for when you see exactly what you want!
# vi-forward-char                                 : Using vi mode? Press 'l' to accept suggestion character by character. Vi-style autocompletion!
# vi-end-of-line                                  : In vi mode, press '$' to accept entire suggestion. Quick way to grab that full command!
# vi-add-eol                                      : Vi mode's 'A' key - jumps to end AND accepts full suggestion. One key to rule them all!
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=("${(@)ZSH_AUTOSUGGEST_ACCEPT_WIDGETS}")

### ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS (https://bit.ly/4j6Tww9) - WIDGETS IN THIS ARRAY WILL PARTIALLY ACCEPT THE SUGGESTION WHEN INVOKED:
# forward-word                                    :Press ALT+F/ESC+F to accept suggestion up to next word. Quick way to grab partial matches!
# emacs-forward-word                              :Emacs style word jumping (ALT+F) to accept suggestion word by word. Precise control!
# vi-forward-word                                 :Vi's 'w' command accepts suggestion until next word start. Familiar vi navigation!
# vi-forward-word-end                             :Vi's 'e' accepts suggestion to end of next word. Perfect for partial completions!
# vi-forward-blank-word                           :Vi's 'W' for bigger jumps - accepts until next space-separated word. Fast navigation!
# vi-forward-blank-word-end                       :Vi's 'E' accepts to end of next space-separated word. Quick way to grab chunks!
# vi-find-next-char                               :Vi's 'f' key accepts suggestion up to character you specify. Precise acceptance!
# vi-find-next-char-skip                          :Vi's 't' accepts up to (but not including) specified char. Fine-tuned control!
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=("${(@)ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS}")

### ZSH_AUTOSUGGEST_IGNORE_WIDGETS (https://bit.ly/40sVKyz) - WIDGETS IN THIS ARRAY WILL NOT TRIGGER ANY CUSTOM BEHAVIOR:
# orig-*                                          :Blocks suggestions during original widget behavior. Keeps things predictable!
# beep                                            :No suggestions when terminal beeps. Because nobody likes surprises with error sounds!
# run-help                                        :Looking up command help? Suggestions pause so you can read docs clearly.
# set-local-history                               :Switching history contexts? Suggestions wait until you're done.
# which-command                                   :Using 'which' to find commands? Suggestions step aside for clean results.
# yank                                            :Pasting with CTRL+Y? No suggestions mixing with your clipboard content!
# yank-pop                                        :Cycling through kill ring? Suggestions pause until you find what you need.
# zle-*                                           :ZLE (Zsh Line Editor) internal stuff - suggestions don't interfere with editor magic!
ZSH_AUTOSUGGEST_IGNORE_WIDGETS=("${(@)ZSH_AUTOSUGGEST_IGNORE_WIDGETS}")

### ZSH_AUTOSUGGEST_EXECUTE_WIDGETS (https://bit.ly/42acICW) - WIDGETS IN THIS ARRAY WILL EXECUTE THE SUGGESTION WHEN INVOKED:
ZSH_AUTOSUGGEST_EXECUTE_WIDGETS=("${(@)ZSH_AUTOSUGGEST_EXECUTE_WIDGETS}")
