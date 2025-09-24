#!/usr/bin/env zsh

# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc

# HELPERS {
  # Redirects stdout (file descriptor 1) to /dev/null
  # Then redirects stderr (file descriptor 2) to wherever stdout is going (which is now /dev/null)
  # Works in all POSIX-compliant shells (sh, dash, bash, zsh, etc.)
  _has_command() {
    command -v "$1" >/dev/null 2>&1
  }
# }

# COMMON VARS & COLORS | https://en.wikipedia.org/wiki/LS_COLORS {
  export DIRSTACKSIZE=${DIRSTACKSIZE:-100}
  export PAGER=${PAGER:-"less -FREXi"}
  export BROWSER=${BROWSER:-"open"}
  export MANROFFOPT=${MANROFFOPT:-"-c"}
  export CLICOLOR=${CLICOLOR:-1}
  export LSCOLORS=EgCeDdEeCcghhahahacac
  export LS_COLORS='di=0;38;2;122;162;247:ln=0;38;2;42;195;222:ex=1;38;2;158;206;106:fi=0;38;2;192;202;245:pi=0;38;2;65;72;104:so=0;38;2;65;72;104:bd=0;38;2;224;175;104:cd=0;38;2;224;175;104:su=0;38;2;255;0;124:sg=0;38;2;255;0;124:tw=0;38;2;255;0;124:ow=0;38;2;255;0;124:st=0;38;2;255;0;124:mi=0;38;2;157;124;216:or=0;38;2;157;124;216:*.c=0;38;2;158;206;106:*.h=0;38;2;158;206;106:*.cpp=0;38;2;158;206;106:*.hpp=0;38;2;158;206;106:*.cc=0;38;2;158;206;106:*.cxx=0;38;2;158;206;106:*.py=0;38;2;158;206;106:*.js=0;38;2;158;206;106:*.ts=0;38;2;158;206;106:*.tsx=0;38;2;158;206;106:*.jsx=0;38;2;158;206;106:*.rs=0;38;2;158;206;106:*.go=0;38;2;158;206;106:*.java=0;38;2;158;206;106:*.kt=0;38;2;158;206;106:*.swift=0;38;2;158;206;106:*.rb=0;38;2;158;206;106:*.php=0;38;2;158;206;106:*.pl=0;38;2;158;206;106:*.sh=0;38;2;158;206;106:*.bash=0;38;2;158;206;106:*.zsh=0;38;2;158;206;106:*.fish=0;38;2;158;206;106:*.lua=0;38;2;158;206;106:*.vim=0;38;2;158;206;106:*.el=0;38;2;158;206;106:*.clj=0;38;2;158;206;106:*.hs=0;38;2;158;206;106:*.ml=0;38;2;158;206;106:*.fs=0;38;2;158;206;106:*.fsx=0;38;2;158;206;106:*.fsi=0;38;2;158;206;106:*.dart=0;38;2;158;206;106:*.scala=0;38;2;158;206;106:*.groovy=0;38;2;158;206;106:*.gradle=0;38;2;158;206;106:*.sbt=0;38;2;158;206;106:*.kts=0;38;2;158;206;106:*.sql=0;38;2;158;206;106:*.r=0;38;2;158;206;106:*.jl=0;38;2;158;206;106:*.cr=0;38;2;158;206;106:*.ex=0;38;2;158;206;106:*.exs=0;38;2;158;206;106:*.cs=0;38;2;158;206;106:*.vb=0;38;2;158;206;106:*.pas=0;38;2;158;206;106:*.dpr=0;38;2;158;206;106:*.inc=0;38;2;158;206;106:*.asm=0;38;2;158;206;106:*.s=0;38;2;158;206;106:*.S=0;38;2;158;206;106:*.ll=0;38;2;158;206;106:*.bc=0;38;2;158;206;106:*.mir=0;38;2;158;206;106:*.erl=0;38;2;158;206;106:*.hrl=0;38;2;158;206;106:*.app.src=0;38;2;158;206;106:*.app=0;38;2;158;206;106:*.appup=0;38;2;158;206;106:*.rel=0;38;2;158;206;106:*.config=0;38;2;42;195;222:*.conf=0;38;2;42;195;222:*.cfg=0;38;2;42;195;222:*.ini=0;38;2;42;195;222:*.toml=0;38;2;42;195;222:*.yaml=0;38;2;42;195;222:*.yml=0;38;2;42;195;222:*.json=0;38;2;42;195;222:*.xml=0;38;2;42;195;222:*.html=0;38;2;42;195;222:*.htm=0;38;2;42;195;222:*.css=0;38;2;42;195;222:*.scss=0;38;2;42;195;222:*.sass=0;38;2;42;195;222:*.less=0;38;2;42;195;222:*.md=0;38;2;122;162;247:*.markdown=0;38;2;122;162;247:*.rst=0;38;2;122;162;247:*.tex=0;38;2;122;162;247:*.ltx=0;38;2;122;162;247:*.sty=0;38;2;122;162;247:*.cls=0;38;2;122;162;247:*.bib=0;38;2;122;162;247:*.bst=0;38;2;122;162;247:*.dot=0;38;2;122;162;247:*.gv=0;38;2;122;162;247:*.ui=0;38;2;122;162;247:*.glade=0;38;2;122;162;247:*.desktop=0;38;2;122;162;247:*.service=0;38;2;122;162;247:*.timer=0;38;2;122;162;247:*.socket=0;38;2;122;162;247:*.target=0;38;2;122;162;247:*.mount=0;38;2;180;249;248:*.automount=0;38;2;180;249;248:*.swap=0;38;2;180;249;248:*.path=0;38;2;180;249;248:*.slice=0;38;2;180;249;248:*.scope=0;38;2;180;249;248:*.nix=0;38;2;42;195;222:*.flake=0;38;2;42;195;222:*.lock=0;38;2;42;195;222:*.gitignore=0;38;2;42;195;222:*.gitattributes=0;38;2;42;195;222:*.gitmodules=0;38;2;42;195;222:*.gitconfig=0;38;2;42;195;222:*.hgrc=0;38;2;42;195;222:*.hgignore=0;38;2;42;195;222:*.svnignore=0;38;2;42;195;222:*.bzrignore=0;38;2;42;195;222:*.cvsignore=0;38;2;42;195;222:*.dockerignore=0;38;2;42;195;222:*.fdignore=0;38;2;42;195;222:*.rgignore=0;38;2;42;195;222:*.ignore=0;38;2;42;195;222:*.editorconfig=0;38;2;42;195;222:'
  export EXA_COLORS="di=1;38;2;122;162;247:ex=01;38;5;10:fi=0;38;2;192;202;245:pi=2;38;2;65;72;104:so=3;38;2;65;72;104:bd=4;38;2;224;175;104:cd=0;38;2;224;175;104:ln=04;01;38;5;205:or=0;38;2;157;124;216:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
# }

# ZSH OPTIONS | http://zsh.sourceforge.io/Doc/Release/Options {
  # Some generic Zsh built-in environment options are set by ZIM (https://github.com/zimfw/zimfw)
  # Add these to your .zshrc after the ZIM initialization block to ensure proper loading order
  # More: https://github.com/zimfw/environment

  # EXPANSION-AND-GLOBBING | http://zsh.sourceforge.io/Doc/Release/Options.html#Expansion-and-Globbing
  setopt bad_pattern       # Reports bad patterns during globbing => `[[ 1 = 2 ]]` will print an error
  setopt brace_ccl         # Enables brace character class lists expansion => `echo {a..z}` will print `abcdefghijklmnopqrstuvwxyz`
  setopt numeric_glob_sort # Natural number sorting | Sort filenames numerically when it makes sense => `ls file*` shows: file1 file2 file10 (rather than file1 file10 file2)
  # }

  # HISTORY | http://zsh.sourceforge.io/Doc/Release/Options.html#History
  setopt bang_hist              # Treat the `!` character specially during expansion => `!ls` will execute `ls`
  setopt extended_history       # Save each command's beginning timestamp and the duration => `history` will print `beginning_timestamp duration command`
  setopt hist_expire_dups_first # When trimming history, remove duplicates and commands that begin with a space => `history -c` will remove duplicates and commands that begin with a space
  setopt hist_ignore_all_dups   # When trimming history, remove duplicates => `history -c` will remove duplicates
  setopt hist_reduce_blanks     # Remove superfluous blanks from each command line being added to the history list => `history -c` will remove superfluous blanks
  setopt hist_subst_pattern     # Perform pattern substitution on history expansion => `history -c` will perform pattern substitution on history expansion
  # }

  # INPUT OUTPUT | http://zsh.sourceforge.io/Doc/Release/Options.html#Input_002fOutput
  setopt hash_cmds   # Improves command execution speed | Keep hash table of commands for faster execution => First run is slower as path is hashed: `ls -l /usr/bin/ls  # ~100ms`. Subsequent runs are faster using hash table: `ls -l /usr/bin/ls  # ~10ms`
  setopt hash_dirs   # Improves command execution speed | Keep hash table of directories for faster execution => First run is slower as path is hashed: `ls /usr/local/bin  # ~100ms`. Subsequent runs are faster using hash table: `ls /usr/local/bin  # ~10ms`
  setopt path_dirs   # Improves command execution speed | Perform path search even on command names with slashes => `ls -l /usr/bin/ls` will print `/usr/bin/ls`
  setopt rc_quotes   # Easier string handling | Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
  setopt short_loops # Shorter one-line loops | Enable shortened loop syntax => It allows `for i in *; echo $i` to be used instead of `for i in *; do echo $i; done`

  # [SET BY ZIM!!] Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
  setopt no_mail_warning
  setopt no_mailwarn
  setopt no_mailwarning
  # }

  # PROMPTING | http://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
  setopt transient_rprompt # Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
  # }

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
  zstyle ':completion:*' menu select=2                                                                         # Menu select
  zstyle ':completion:*' list-prompt '%S%M matches%s'                                                          # List prompt
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'                                                    # Case insensitive tab completion
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'                # Case senstive correction and complete partial words
  zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s                           # Select prompt
  zstyle ':completion:*' use-compctl false                                                                     # Disable compctl
  zstyle ':completion:*' complete yes                                                                          # Enable completion
  zstyle ':completion:*' verbose true                                                                          # Verbose completion
  zstyle ':completion:*' case-sensitive no                                                                     # Case-sensitive completion
  zstyle ':completion:*' file-list all                                                                         # List all files
  zstyle ':completion:*' file-sort name                                                                        # Sort files by name
  zstyle ':completion:*' accept-exact '*(N)'                                                                   # Allows completion to work on empty directories
  zstyle ':completion:*' accept-exact-dirs 'yes'                                                               # Accept exact matches for directories
  zstyle ':completion:*' special-dirs yes                                                                      # Include special directories
  zstyle ':completion:*' list-suffixes yes                                                                     # Show suffixes
  zstyle ':completion:*' strip-comments yes                                                                    # Strip comments
  zstyle ':completion:*' list-dirs-first yes                                                                   # List directories first
  zstyle ':completion:*' squeeze-slashes no                                                                    # Don't squeeze slashes
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
# }

# ZSH PARAMETERS | http://zsh.sourceforge.io/Doc/Release/Parameters.html {
  # General ZSH's parameters related to prompt
  export PROMPT='❯ '
  # If set, used to give the indentation between the right hand side of the right prompt in the line editor as given by RPS1 or RPROMPT and the right hand side of the screen. If not set, the value 1 is used. See https://superuser.com/a/726509/389767
  export ZLE_RPROMPT_INDENT=0
  # PATH; Where the shell searches for commands; set PATH so it includes user's private bin if it exists
  declare -gaU path=(${XDG_LOCAL_BIN_DIR:-$HOME/.local}/bin ${CARGO_HOME:-$XDG_DATA_HOME/cargo}/bin ${NPM_CONFIG_PREFIX:-$XDG_DATA_HOME/npm}/bin ${PNPM_HOME:-$XDG_DATA_HOME/pnpm}/bin $path)
  # FPATH; Where the shell searches to find shell functions
  declare -gaU fpath=($ZIM_HOME/functions $fpath)
  # CDPATH; Directories that the shell searches to find the current directory when the user changes directories using the cd command
  declare -gaU cdpath=($HOME $XDG_CONFIG_HOME $ZDOTDIR $cdpath)
  # MANPATH; Directories that the shell searches to find the manual pages
  export -a manpath=($manpath)
# }

# HOMEBREW | https://brew.sh{
  # The missing package manager for macOS (and Linux)
  # Determine Homebrew environment variables based on OS and architecture and load it
  # https://docs.brew.sh/Manpage#bundle-subcommand
  if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-$(if [[ -x /opt/homebrew/bin/brew ]]; then echo "/opt/homebrew"; elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then echo "/home/linuxbrew/.linuxbrew"; elif [[ -x /usr/local/bin/brew ]]; then echo "/usr/local"; else echo "/usr/local"; fi)}
    export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
    export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
    export HOMEBREW_OPT=$HOMEBREW_PREFIX/opt
    export HOMEBREW_NO_ENV_HINTS=1                # Hide hints
    export HOMEBREW_NO_ANALYTICS=1                # Disabled analytics
    export HOMEBREW_BAT=true                      # Use bat for the brew cat command
    export HOMEBREW_BAT_THEME=dracula             # Use this as the bat theme for syntax highlighting
    export HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1       # Don't dump vscode extensions
    export HOMEBREW_BUNDLE_FILE=${HOMEBREW_BUNDLE_FILE:-$XDG_CONFIG_HOME/homebrew/Brewfile}
    eval "$("$HOMEBREW_BIN"/brew shellenv)"
    path=(
      $HOMEBREW_PREFIX/opt/{ruby,gems,curl,rustup}/bin
      $HOMEBREW_PREFIX/opt/gawk/libexec/gnubin
      $HOMEBREW_PREFIX/{bin,sbin}
      $path
    )
  fi
# }

# FLOX | https://flox.dev/docs/tutorials/default-environment {
  # Activate the Default Environment
  if _has_command flox; then
    eval "$(FLOX_SHELL=/usr/bin/zsh flox activate --dir $( [[ -e ~/.flox ]] && echo ~ || echo ~/.config/flox ) -m run)"
  fi
# }

# LOCAL/DEV ENVIRONMENT VARIABLES {
if _has_command sops age && [[ -r $HOME/.config/.env ]]; then
  set -a
  source "$HOME/.config/.env"
  set +a
fi
# }

# EDITOR {
  # Set default editor to nvim, vim or vi
  # https://neovim.io/doc/user/starting.html#config
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
# }

# TERM {
  if [ "$TERM_PROGRAM" = "ghostty" ]; then
    if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
      source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
    fi
    export SNACKS_GHOSTTY=true
  fi
  export TERM="${TERM:-xterm-256color}"
# }

# SHELL {
  export SHELL=${SHELL:-"$(which zsh)"}
# }

# ZIM | https://zimfw.sh {
  # The Zsh configuration framework with blazing speed and modular extensions.
  # Download zimfw plugin manager if missing
  if [[ ! -e $ZIM_HOME/zimfw.zsh ]]; then
    ZIM_URL="https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL --create-dirs -o $ZIM_HOME/zimfw.zsh $ZIM_URL
    elif command -v wget >/dev/null 2>&1; then
      mkdir -p $ZIM_HOME && wget -nv -O $ZIM_HOME/zimfw.zsh $ZIM_URL
    else
      echo "ZIM could not be installed: curl or wget is required!"
    fi
  fi
  # Install missing modules, and update $ZIM_HOME/init.zsh if missing or outdated
  if [[ ! $ZIM_HOME/init.zsh -nt $ZDOTDIR/.zimrc ]]; then
    source $ZIM_HOME/zimfw.zsh init -q
  fi
  # Initialize modules
  if [[ -f $ZIM_HOME/init.zsh ]]; then
    source $ZIM_HOME/init.zsh
  fi
# }

# ZPROF {
  # profilling
  if [[ -n "$z_prof" ]]; then
    if [[ -n "$z_trace" ]]; then
      unsetopt XTRACE
      exec 2>&3 3>&-
      zprof >$ZDOTDIR/tmp/benchmark.$$.prof.log
    else
      zprof
    fi
    zmodload -u zsh/zprof
  elif [[ -n "$z_trace" ]]; then
    unsetopt XTRACE
  fi
# }
