#!/usr/bin/env zsh
# Shell environment: helpers, options, search paths, package manager, editor.
# Loaded by .zshrc; defines functions only — nothing runs at load time.
#DECLARES env::core  env::options  env::paths  env::homebrew  env::editor  _has_command

# Predicate used by several modules. Defined at file scope so it is available
# as soon as this module loads, before any zrc:: function runs.
# True only when every named command exists.
_has_command() {
  local _c
  for _c in "$@"; do
    command -v "$_c" >/dev/null 2>&1 || return 1
  done
  return 0
}

#ABOUT Identify the shell binary.
env::core() {
  export SHELL=${SHELL:-"$(which zsh)"}
}

#ABOUT Set zsh shell options (globbing, history, completion, ZLE).
#ORDER Must NOT use `emulate -L zsh`: LOCAL_OPTIONS would revert these on return.
env::options() {
  # Some generic Zsh built-in environment options are set by ZIM (https://github.com/zimfw/zimfw)
  # Add these to your .zshrc after the ZIM initialization block to ensure proper loading order
  # More: https://github.com/zimfw/environment

  # EXPANSION-AND-GLOBBING | http://zsh.sourceforge.io/Doc/Release/Options.html#Expansion-and-Globbing
  setopt bad_pattern       # Reports bad patterns during globbing => `[[ 1 = 2 ]]` will print an error
  setopt brace_ccl         # Enables brace character class lists expansion => `echo {a..z}` will print `abcdefghijklmnopqrstuvwxyz`
  setopt numeric_glob_sort # Natural number sorting | Sort filenames numerically when it makes sense => `ls file*` shows: file1 file2 file10 (rather than file1 file10 file2)
  # }

  # HISTORY | http://zsh.sourceforge.io/Doc/Release/Options.html#History
  HISTSIZE=${HISTSIZE:-10000}   # Maximum number of commands to keep in memory
  SAVEHIST=${SAVEHIST:-10000}   # Maximum number of commands to save to history file
  setopt bang_hist              # Treat the `!` character specially during expansion => `!ls` will execute `ls`
  setopt extended_history       # Save each command's beginning timestamp and the duration => `history` will print `beginning_timestamp duration command`
  setopt inc_append_history     # Append history incrementally (after each command) rather than only at shell exit
  setopt hist_expire_dups_first # When trimming history, remove duplicates and commands that begin with a space => `history -c` will remove duplicates and commands that begin with a space
  setopt hist_ignore_all_dups   # When trimming history, remove duplicates => `history -c` will remove duplicates
  setopt hist_reduce_blanks     # Remove superfluous blanks from each command line being added to the history list => `history -c` will remove superfluous blanks
  setopt hist_subst_pattern     # Perform pattern substitution on history expansion => `history -c` will perform pattern substitution on history expansion
  # Load history file explicitly (required because NO_RCS prevents automatic loading)
  [[ -r "$HISTFILE" ]] && fc -R "$HISTFILE"
  # Save history on shell exit (backup to incremental saves)
  autoload -Uz add-zsh-hook
  zsh_history_save() {
    fc -W "$HISTFILE"
  }
  add-zsh-hook zshexit zsh_history_save
  # }

  # INPUT OUTPUT | http://zsh.sourceforge.io/Doc/Release/Options.html#Input_002fOutput
  setopt hash_cmds   # Improves command execution speed | Keep hash table of commands for faster execution => First run is slower as path is hashed: `ls -l /usr/bin/ls  # ~100ms`. Subsequent runs are faster using hash table: `ls -l /usr/bin/ls  # ~10ms`
  setopt hash_dirs   # Improves command execution speed | Keep hash table of directories for faster execution => First run is slower as path is hashed: `ls /usr/local/bin  # ~100ms`. Subsequent runs are faster using hash table: `ls /usr/local/bin  # ~10ms`
  setopt path_dirs   # Improves command execution speed | Perform path search even on command names with slashes => `ls -l /usr/bin/ls` will print `/usr/bin/ls`
  setopt rc_quotes   # Easier string handling | Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
  setopt short_loops # Shorter one-line loops | Enable shortened loop syntax => It allows `for i in *; echo $i` to be used instead of `for i in *; do echo $i; done`

  # }

  # PROMPTING | http://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
  setopt transient_rprompt # Remove the right prompt from previous lines, keeping scrollback clean when copying commands

  # SCRIPTS AND FUNCTIONS | http://zsh.sourceforge.io/Doc/Release/Options.html#Scripts-and-Functions
  setopt alias_func_def    # Advanced shell customization | Allows alias and function with same name => `alias ls='ls --color=auto'` and `function ls() { command ls --color=auto "$@" }` will work
  setopt bsd_echo          # Cross-platform scripts | Makes echo behave like BSD echo => `echo "Hello\nWorld"` prints literal `\n` whereas `echo -e "Hello\nWorld"` prints on two lines
  setopt sh_file_expansion # sh-compatibility needs | Makes file expansion sh-compatible => `ls !(*.txt)` will list all files except those with the .txt extension
  setopt typeset_silent    # Cleaner script output | Suppresses typeset command output => `typeset -A myarray` will not print `myarray`
  # }

  # JOB CONTROL | http://zsh.sourceforge.io/Doc/Release/Options.html#Job-Control
  setopt auto_resume # Resume background jobs automatically | Resume background jobs automatically => `ls &` will resume the job even if the shell is closed
  # }

  # ZLE | http://zsh.sourceforge.io/Doc/Release/Options.html#Zle
  setopt combining_chars # Multilingual text handling | Handles Unicode combining characters => `echo "e\u0301"` outputs: é
  setopt no_beep         # Reduces notification noise | Silences beeps on tab completion errors => `ls -l /usr/bin/ls` will not print a beep when tab completing
  setopt no_flow_control # Disables ^S/^Q flow control | Frees up ^S for history search and ^Q for exiting the shell => `C-q` will not suspend the shell
  # }

  # COMPLETIONS | http://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4 {
  setopt auto_list        # Completion Navigation | Automatically list choices on ambiguous completion.
  setopt auto_menu        # Completion Navigation | Automatically show completion menu on successive tab.
  setopt auto_param_keys  # Parameter Completion | Intelligently add space after = or :.
  setopt auto_param_slash # Parameter Completion | Automatically insert a slash when completing a directory
  setopt complete_in_word # Completion Navigation | Complete from both ends of a word.
  setopt glob_dots        # Globbing | Include dotfiles in globbing
  setopt list_ambiguous   # Completion Navigation | Show unambiguous prefix first
  # }

  # https://no-color.org
  unset NO_COLOR
  # }

  # ZSH COMPLETIONS SETTINGS | http://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4 {
  zstyle ':completion:*' list-colors "$LS_COLORS"
  zstyle ':completion:*' auto-description 'specify: %d'                                                        # Auto description
  zstyle ':completion:*' completer _expand _complete _correct _approximate _expand_alias _extensions _match    # Completers
  zstyle ':completion:*' format 'Completing %d'                                                                # Format
  zstyle ':completion:*' group-name ''                                                                         # Group name
  zstyle ':completion:*' list-prompt '%S%M matches%s'                                                          # List prompt
  zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s                           # Select prompt
  zstyle ':completion:*' use-compctl false                                                                     # Disable compctl
  zstyle ':completion:*' complete yes                                                                          # Enable completion
  zstyle ':completion:*' case-sensitive no                                                                     # Case-sensitive completion
  zstyle ':completion:*' file-list all                                                                         # List all files
  zstyle ':completion:*' file-sort name                                                                        # Sort files by name
  zstyle ':completion:*' accept-exact '*(N)'                                                                   # Allows completion to work on empty directories
  zstyle ':completion:*' accept-exact-dirs 'yes'                                                               # Accept exact matches for directories
  zstyle ':completion:*' special-dirs yes                                                                      # Include special directories
  zstyle ':completion:*' list-suffixes yes                                                                     # Show suffixes
  zstyle ':completion:*' strip-comments yes                                                                    # Strip comments
  zstyle ':completion:*' list-dirs-first yes                                                                   # List directories first
  zstyle ':completion:*' fzf-search-display true                                                               # Enable fzf search display
  zstyle ':completion:*' preserve-prefix '//[^/]##/'                                                           # Preserve prefix
  zstyle ':completion:*' use-cache on                                                                          # Use cache
  zstyle ':completion:*' cache-path "$ZSH_COMPCACHE"                                                           # Cache path
  zstyle ':completion::complete:*' rehash yes                                                                  # Rehash
  zstyle ':completion::complete:*' gain-privileges 1                                                           # Gain privileges
  zstyle ':completion:*:functions' ignored-patterns '_*'                                                       # Ignore internal functions
  zstyle ':completion:*:match:*' original only                                                                 # Match original only
  zstyle ':completion:*:*:cd:*' tag-order local-directories named-directories directory-stack path-directories # CD tag order
  zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'         # Tilde group order
  zstyle ':completion:*:kill:*' command 'ps -u $LOGNAME -o pid,%cpu,tty,cputime,cmd'
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
  zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,comm -w'                                      # Processes command
  zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)' # Max errors
}

#ABOUT Populate path, fpath, cdpath and manpath.
#ORDER Before env::homebrew, which prepends to $path.
env::paths() {
  # PATH; Where the shell searches for commands; set PATH so it includes user's private bin if it exists
  declare -gaU path=(${XDG_LOCAL_BIN_DIR:-$HOME/.local/bin} ${CARGO_HOME:-$XDG_DATA_HOME/cargo/bin} ${NPM_CONFIG_PREFIX:-$XDG_DATA_HOME/npm/bin} ${PNPM_HOME:-$XDG_DATA_HOME/pnpm} /usr/local/{bin,sbin} $HOME/.turso $path)
  # FPATH; Where the shell searches to find shell functions
  declare -gaU fpath=($ZIM_HOME/functions $fpath)
  # CDPATH; Directories that the shell searches to find the current directory when the user changes directories using the cd command
  declare -gaU cdpath=($HOME $XDG_CONFIG_HOME $ZDOTDIR $cdpath)
  # MANPATH; Directories that the shell searches to find the manual pages
  export -a manpath=($manpath)
}

#ABOUT Export HOMEBREW_* settings and add brew prefixes to $path.
#ORDER After env::paths.
env::homebrew() {
  # mise's brew: packages fill the prefix without installing brew itself, so the prefix is found by its folders.
  if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$(if [[ -d /opt/homebrew ]]; then echo "/opt/homebrew"; elif [[ -d /home/linuxbrew/.linuxbrew ]]; then echo "/home/linuxbrew/.linuxbrew"; else echo "/usr/local"; fi)}
    export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
    export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
    export HOMEBREW_OPT=$HOMEBREW_PREFIX/opt
    export HOMEBREW_NO_ENV_HINTS=1                # Hide hints
    export HOMEBREW_NO_ANALYTICS=1                # Disabled analytics
    export HOMEBREW_BAT=true                      # Use bat for the brew cat command
    export HOMEBREW_BAT_THEME=dracula             # Use this as the bat theme for syntax highlighting
    export HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1       # Don't dump vscode extensions
    export HOMEBREW_BUNDLE_FILE=${HOMEBREW_BUNDLE_FILE:-$XDG_CONFIG_HOME/homebrew/Brewfile}
    [[ -x $HOMEBREW_BIN/brew ]] && eval "$("$HOMEBREW_BIN"/brew shellenv)"
    path=(
      $HOMEBREW_PREFIX/opt/{ruby,gems,curl,rustup,awscli@1}/bin
      $HOMEBREW_PREFIX/opt/gawk/libexec/gnubin
      $HOMEBREW_PREFIX/{bin,sbin}
      $path
    )
  fi
}

#ABOUT Select EDITOR/VISUAL/GIT_EDITOR and the vim aliases.
env::editor() {
  if _has_command nvim; then
    export EDITOR=${EDITOR:-"$(command -v nvim)"}
    export VIM_PATH=${VIM_PATH:-$XDG_CONFIG_HOME/nvim}
    export MYVIMRC=${MYVIMRC:-$VIM_PATH/init.lua}
    export NVIM_LOG_FILE=${NVIM_LOG_FILE:-$XDG_CACHE_HOME/nvim/.nvimlog}
    alias vim=nvim
    alias vi=nvim
  else
    export EDITOR=${EDITOR:-"$(command -v vim || command -v vi)"}
    alias vi=vim
  fi
  export VISUAL=${VISUAL:-$EDITOR}
  export SUDO_EDITOR=${SUDO_EDITOR:-$EDITOR}
  export GIT_EDITOR=${GIT_EDITOR:-"$EDITOR -c 'startinsert'"}
  export LAUNCH_EDITOR=${LAUNCH_EDITOR:-$EDITOR}
}

env::core                    # shell identity
env::options                 # shell options
env::paths                   # path, fpath, cdpath, manpath
env::homebrew                # brew shellenv and prefixes
env::editor                  # EDITOR, VISUAL, GIT_EDITOR, vim aliases
