# # ZSH OPTIONS
  # CHANGING DIRECTORIES OPTIONS {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Changing-Directories
    setopt AUTO_CD           # If a command is issued that can’t be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory. This option is only applicable if the option SHIN_STDIN is set, i.e. if commands are being read from standard input. The option is designed for interactive use; it is recommended that cd be used explicitly in scripts to avoid ambiguity.
    setopt AUTO_PUSHD        # Make cd push the old directory onto the directory stack.
    setopt CHASE_LINKS       # Resolve symbolic links to their true values when changing directory. This also has the effect of CHASE_DOTS, i.e. a ‘..’ path segment will be treated as referring to the physical parent, even if the preceding path segment is a symbolic link.
    setopt CHASE_DOTS        # When changing to a directory containing a path segment ‘..’ which would otherwise be treated as canceling the previous segment in the path (in other words, ‘foo/..’ would be removed from the path, or if ‘..’ is the first part of the path, the last part of the current working directory would be removed), instead resolve the path to the physical directory. This option is overridden by CHASE_LINKS. For example, suppose /foo/bar is a link to the directory /alt/rod. Without this option set, ‘cd /foo/bar/..’ changes to /foo; with it set, it changes to /alt. The same applies if the current directory is /foo/bar and ‘cd ..’ is used. Note that all other symbolic links in the path will also be resolved.
    setopt PUSHD_IGNORE_DUPS # DO NOT push multiple copies of the same directory onto the directory stack.
    setopt PUSHD_TO_HOME     # Have pushd with no arguments act like ‘pushd $HOME’.
    setopt PUSHD_SILENT      # DO NOT print the directory stack after pushd or popd
    setopt CD_SILENT         # Never print the working directory after a cd (whether explicit or implied with the AUTO_CD option set). cd normally prints the working directory when the argument given to it was -, a stack entry, or the name of a directory found under CDPATH. Note that this is distinct from pushd’s stack-printing behaviour, which is controlled by PUSHD_SILENT. This option overrides the printing-related effects of POSIX_CD
    # https://www.notion.so/zrcsh-de5aadec10644fe88cb5a6d51b9bf202
    # https://github.com/zsh-users/zsh/blob/master/Functions/Chpwd/cdr
    zstyle ':chpwd:' recent-dirs-default true
    zstyle ':chpwd:' recent-dirs-file $ZSH_CACHE_DIR/chpwd-recent-dirs
    zstyle ':chpwd:' recent-dirs-max 100
    zstyle ':chpwd:*' recent-dirs-pushd true
    zstyle ':completion:*' recent-dirs-insert both
  # }

  # EXPANSION-AND-GLOBBING {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Expansion-and-Globbing
    setopt    BAD_PATTERN                                           # If a pattern for filename generation is badly formed, print an error message. (If this option is unset, the pattern will be left unchanged.)
    setopt    NOMATCH                                               # If a pattern for filename generation has no matches, print an error, instead of leaving it unchanged in the argument list. This also applies to file expansion of an initial ‘~’ or ‘=’.
    setopt    GLOB_DOTS                                             # DO NOT require a leading ‘.’ in a filename to be matched explicitly.
    setopt    EXTENDED_GLOB                                         # Treat the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename generation, etc. (An initial unquoted ‘~’ always produces named directory expansion.)
    setopt    BRACE_CCL                                             # Expand expressions in braces which would not otherwise undergo brace expansion to a lexically ordered list of all the characters.
    setopt    MARK_DIRS                                             # Append a trailing ‘/’ to all directory names resulting from filename generation (globbing).
    setopt    NUMERIC_GLOB_SORT                                     # If numeric filenames are matched by a filename generation pattern, sort the filenames numerically rather than lexicographically.
    setopt    NO_CASE_GLOB                                          # DO NOT Make globbing (filename generation) sensitive to case. Note that other uses of patterns are always sensitive to case. If the option is unset, the presence of any character which is special to filename generation will cause case-insensitive matching. For example, cvs(/) can match the directory CVS owing to the presence of the globbing flag (unless the option BARE_GLOB_QUAL is unset).
  # }

  # HISTORY {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#History
    setopt    APPEND_HISTORY                          # If this is set, zsh sessions will append their history list to the history file, rather than replace it. Thus, multiple parallel zsh sessions will all have the new entries from their history lists added to the history file, in the order that they exit. The file will still be periodically re-written to trim it when the number of lines grows 20% beyond the value specified by $SAVEHIST (see also the HIST_SAVE_BY_COPY option).
    setopt    EXTENDED_HISTORY                        # Save each command’s beginning timestamp (in seconds since the epoch) and the duration (in seconds) to the history file.
    setopt    HIST_EXPIRE_DUPS_FIRST                  # Expire A Duplicate Event First When Trimming History.
    setopt    BANG_HIST                               # Treat The '!' Character Specially During Expansion.
    setopt    SHARE_HISTORY                           # Share History Between All Sessions. This option both imports new commands from the history file, and also causes your typed commands to be appended to the history file (the latter is like specifying INC_APPEND_HISTORY, which should be turned off if this option is in effect). The history lines are also output with timestamps ala EXTENDED_HISTORY (which makes it easier to find the spot where we left off reading the file after it gets re-written).
    setopt    HIST_IGNORE_DUPS                        # DO NOT Record An Event That Was Just Recorded Again.
    # setopt    HIST_FIND_NO_DUPS                       # DO NOT Display A Previously Found Event.
    setopt    HIST_IGNORE_SPACE                       # DO NOT Record An Event Starting With A Space.
    setopt    HIST_REDUCE_BLANKS                      # Remove superfluous blanks from each command line being added to the history list.
    setopt    HIST_VERIFY                             # DO NOT Execute Immediately Upon History Expansion.
    setopt    HIST_SUBST_PATTERN                      # Substitutions using the :s and :& history modifiers are performed with pattern matching instead of string matching. This occurs wherever history modifiers are valid, including glob qualifiers and parameters. See Modifiers.
    setopt    HIST_IGNORE_ALL_DUPS                    # delete old recorded entry if new entry is a duplicate
  # }

  # INPUT OUTPUT {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Input_002fOutput
    setopt    ALIASES                                 # Expand aliases.
    setopt    CLOBBER                                 # Allows ‘>’ redirection to truncate existing files. Otherwise ‘>!’ or ‘>|’ must be used to truncate a file.
    setopt    HASH_CMDS                               # Note the location of each command the first time it is executed. Subsequent invocations of the same command will use the saved location, avoiding a path search. If this option is unset, no path hashing is done at all. However, when CORRECT is set, commands whose names DO NOT appear in the functions or aliases hash tables are hashed in order to avoid reporting them as spelling errors.
    setopt    HASH_EXECUTABLES_ONLY                   # When hashing commands because of HASH_CMDS, check that the file to be hashed is actually an executable. This option is unset by default as if the path contains a large number of commands, or consists of many remote files, the additional tests can take a long time. Trial and error is needed to show if this option is beneficial.
    setopt    HASH_DIRS                               # Whenever a command name is hashed, hash the directory containing it, as well as all directories that occur earlier in the path. Has no effect if neither HASH_CMDS nor CORRECT is set.
    setopt    PATH_DIRS                               # Perform a path search even on command names with slashes in them. Thus if ‘/usr/local/bin’ is in the user’s path, and he or she types ‘X11/xinit’, the command ‘/usr/local/bin/X11/xinit’ will be executed (assuming it exists). Commands explicitly beginning with ‘/’, ‘./’ or ‘../’ are not subject to the path search. This also applies to the ‘.’ and source builtins. Note that subdirectories of the current directory are always searched for executables specified in this form. This takes place before any search indicated by this option, and regardless of whether ‘.’ or the current directory appear in the command search path.
    setopt    RC_QUOTES                               # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.
    unsetopt  MAIL_WARNING                            # DO NOT print a warning message if a mail file has been accessed since the shell last checked.
  # }

  # PROMPTING {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
    setopt    TRANSIENT_RPROMPT                       # DO NOT show command modes on previously accepted lines. Remove any right prompt from display when accepting a command line. This may be useful with terminals with other cut/paste methods.
    setopt    PROMPT_SUBST                            # If set, parameter expansion, command substitution and arithmetic expansion are performed in prompts. Substitutions within prompts DO NOT affect the command status.
  # }

  # SCRIPTS AND FUNCTIONS {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Scripts-and-Functions
    setopt    MULTIOS                                 # Perform implicit tees or cats when multiple redirections are attempted
    setopt    ALIAS_FUNC_DEF                          # By default, zsh does not allow the definition of functions using the ‘name ()’ syntax if name was expanded as an alias: this causes an error. This is usually the desired behaviour, as otherwise the combination of an alias and a function based on the same definition can easily cause problems.
    setopt    SH_FILE_EXPANSION                       # Perform filename expansion (e.g., ~ expansion) before parameter expansion, command substitution, arithmetic expansion and brace expansion. If this option is unset, it is performed after brace expansion, so things like ‘~$USERNAME’ and ‘~{pfalstad,rc}’ will work.
    setopt    BSD_ECHO                                # Make the echo builtin compatible with the BSD man page echo(1) command. This disables backslashed escape sequences in echo strings unless the -e option is specified.
  # }

  # ZLE {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Zle
    setopt    NO_BEEP                                 # DO NOT beep on error in ZLE
    setopt    COMBINING_CHARS                         # Assume that the terminal displays combining characters correctly. Specifically, if a base alphanumeric character is followed by one or more zero-width punctuation characters, assume that the zero-width characters will be displayed as modifications to the base character within the same width. Not all terminals handle this. If this option is not set, zero-width characters are displayed separately with special mark-up. If this option is set, the pattern test [[:WORD:]] matches a zero-width punctuation character on the assumption that it will be used as part of a word in combination with a word character. Otherwise the base shell does not handle combining characters specially.
  # }

  # COMPLETIONS {
    # http://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4
    setopt COMPLETE_IN_WORD     # Complete from both ends of a word.
    setopt ALWAYS_TO_END        # Move cursor to the end of a completed word.
    setopt PATH_DIRS            # Perform path search even on command names with slashes.
    setopt AUTO_MENU            # Show completion menu on a successive tab press.
    setopt AUTO_LIST            # Automatically list choices on ambiguous completion.
    setopt AUTO_PARAM_SLASH     # If completed parameter is a directory, add a trailing slash.
    setopt EXTENDED_GLOB        # Needed for file modification glob modifiers with compinit.
    unsetopt CASE_GLOB          # Case-insensitive (all), partial-word, and then substring completion.
    unsetopt MENU_COMPLETE      # Do not autoselect the first completion entry.
    unsetopt FLOW_CONTROL       # Disable start/stop characters in shell editor.

    # Defaults {
      zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
      zstyle ':completion:*:default' list-prompt '%S%M matches%s'
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' complete true
      zstyle ':completion:*' group-name ''
      zstyle ':completion:*' menu yes
      zstyle ':completion:*' rehash true
      zstyle ':completion:*' file-list all
      zstyle ':completion:*' regular always
      zstyle ':completion:*' file-sort name
      zstyle ':completion:*' use-compctl false
      zstyle ':completion:*' accept-exact '*(N)'
      zstyle ':completion:*' list-suffixes true
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' list-dirs-first true
      zstyle ':completion:*' strip-comments true
      zstyle ':completion:*' preserve-prefix '//[^/]##/'
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*' # Case-insensitive (all), partial-word, and then substring completion
      zstyle ':completion:*' completer _complete _match _approximate
    # }

    # Cache {
      zstyle ':completion:*' use-cache yes
      zstyle ':completion:*' cache-path $ZSH_COMPCACHE
    # }

    # Group matches and describe {
      zstyle ':completion:*:*:*:*:*'      menu yes
      zstyle ':completion:*:matches'      group 'yes'
      zstyle ':completion:*:options'      description 'yes'
      zstyle ':completion:*:options'      auto-description '%d'
      zstyle ':completion:*:functions'    ignored-patterns '(_*|pre(cmd|exec))'
      zstyle ':completion:*:messages'     format '%B%F{purple} -- %d --%f%b'
      zstyle ':completion:*:warnings'     format '%B%F{red}no matches found...%f%b'
      zstyle ':completion:*:corrections'  format '%B%F{green} -- %d --%f%F{magenta}(errors: %e)%f%b'
      zstyle ':completion:*:descriptions' format '[%d]' # set descriptions format to enable group support
    # }

    # Fuzzy match mistyped completions {
      zstyle ':completion:*:match:*' original only
    # }

    # Increase the number of errors based on the length of the typed word. But make sure to cap (at 7) the max-errors to avoid hanging {
      zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)'
    # }

    # Don't complete unavailable commands {
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
    # }

    # Array completion element sorting {
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
    # }

    # Directories {
      zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
      zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
    # }

    # History {
      zstyle ':completion:*:history-words' stop yes
      zstyle ':completion:*:history-words' remove-all-dups yes
      zstyle ':completion:*:history-words' list false
      zstyle ':completion:*:history-words' menu yes
    # }

    # Environment Variables {
      zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}
    # }

    # Ignore multiple entries {
      zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
      zstyle ':completion:*:rm:*' file-patterns '*:all-files'
    # }

    # Kill {
      zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,command -w'
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
      zstyle ':completion:*:*:kill:*' menu yes select
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single
    # }

    # Man {
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.(^1*)' insert-sections true
    # }

    # Media Players {
      zstyle ':completion:*:*:mpg123:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
      zstyle ':completion:*:*:mpg321:*' file-patterns '*.(mp3|MP3):mp3\ files *(-/):directories'
      zstyle ':completion:*:*:ogg123:*' file-patterns '*.(ogg|OGG|flac):ogg\ files *(-/):directories'
      zstyle ':completion:*:*:mocp:*' file-patterns '*.(wav|WAV|mp3|MP3|ogg|OGG|flac):ogg\ files *(-/):directories'
    # }

    # SSH/SCP/RSYNC {
      zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
      zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
      zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
      zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
    # }

    # SSH/SCP/RSYNC {
      zstyle ':completion:*:*:docker:*' option-stacking yes
      zstyle ':completion:*:*:docker-*:*' option-stacking yes
    # }
  # }

  # JOB CONTROL {
    # https://zsh.sourceforge.io/Doc/Release/Options.html#Job-Control
    # setopt    NO_HUP                            # DO NOT Send the HUP signal to running jobs when the shell exits
    # setopt    NO_CHECK_JOBS                     # DO NOT Report the status of background and suspended jobs before exiting a shell with job control; a second attempt to exit the shell will succeed
  # }
# }

# ZSH_PARAMETERS {
  # HISTORY {
    export DIRSTACKSIZE=100
  # }

  # REPORTING {
    # General ZSH's reporting parameters
    # http://zsh.sourceforge.io/Doc/Release/Parameters.html
    export REPORTTIME=10                                # Commands whose combined user and system execution times (measured in seconds) are greater than this value have timing statistics printed for them. Output is suppressed for commands executed within the line editor, including completion; commands explicitly marked with the time keyword still cause the summary to be printed in this case.
    export KEYTIMEOUT=1                                 # Get into vim command mode faster when hitting ESC - Set ESC after-press delay to 0.1s: The time the shell waits, in hundredths of seconds, for another key to be pressed when reading bound multi-character sequences.
  # }

  # PROMPTING {
    # General ZSH's parameters related to prompt
    # http://zsh.sourceforge.io/Doc/Release/Parameters.html
    export PROMPT='❯ '   # default prompt
    export RPROMPT=''    # prompt for right side of screen
    export ZLE_RPROMPT_INDENT=0                       # If set, used to give the indentation between the right hand side of the right prompt in the line editor as given by RPS1 or RPROMPT and the right hand side of the screen. If not set, the value 1 is used. See https://superuser.com/a/726509/389767
    export PROMPT_EOL_MARK=''                         # Don't show a % for partial lines
    export RPROMPT=''                                 # This prompt is displayed on the right-hand side of the screen when the primary prompt is being displayed on the left. This does not work if the SINGLE_LINE_ZLE option is set. It is expanded in the same way as PS1.
    export RPROMPT2=''                                # This prompt is displayed on the right-hand side of the screen when the secondary prompt is being displayed on the left.
    export PS1='❯ '                                   # The primary prompt string, printed before a command is read. It undergoes a special form of expansion before being displayed; see Prompt Expansion. The default is ‘%m%# ’.
    export PS2=''                                     # The secondary prompt, printed when the shell needs more information to complete a command. It is expanded in the same way as PS1. The default is ‘%_> ’, which displays any shell constructs or quotation marks which are currently being processed.
    export PS3=''                                     # Selection prompt used within a select loop. It is expanded in the same way as PS1. The default is ‘?# ’.
    export PS4=''                                     # The execution trace prompt. Default is ‘+%N:%i> ’, which displays the name of the current shell structure and the line number within it. In sh or ksh emulation, the default is ‘+ ’.
  # }

  # typeset -U prevents duplicates variables
  typeset -gaU path fpath cdpath manpath

  # PATH {
    # An array of directories to search for commands.
    # When this parameter is set, each directory is scanned and all files found are put in a hash table.
    # typeset -U PATH prevents duplicates of PATH variables.
    # http://zsh.sourceforge.io/Doc/Release/Parameters.html#index-path
    # https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x
    # https://towardsdatascience.com/my-path-variable-is-a-mess-e52f22bfa520
    # https://koenwoortman.com/zsh-add-directory-to-path/
    path=(
      ${path[@]}
    )
  # }

  # FPATH {
    # An array of directories specifying the search path for function definitions.
    # This path is searched when a function with the -u attribute is referenced. If an executable file is found, then it is read and executed in the current environment.
    # typeset -U PATH prevents duplicates of PATH variables.
    # http://zsh.sourceforge.io/Doc/Release/Parameters.html#index-fpath
    fpath=(
      ~/.bin
      ${XDG_CONFIG_HOME:-$HOME/.config}/zsh/opt/completions
      ${fpath[@]}
    )
  # }

  # CDPATH {
    # An array of directories specifying the search path for the cd command.
    # typeset -U PATH prevents duplicates of PATH variables.
    # http://zsh.sourceforge.io/Doc/Release/Parameters.html#index-cdpath
    cdpath=(
      ${XDG_CONFIG_HOME:-$HOME/.config}/zsh
      ${cdpath[@]}
    )
  # }

  # MANPATH {
    manpath=(
      ${manpath[@]}
    )
  # }
#}

# FUNCTIONS {
  # AUTOLOADED {{
    # A function can be marked as undefined using the autoload builtin (or ‘functions -u’ or ‘typeset -fu’).
    # Such a function has no body. When the function is first executed, the shell searches for its definition using the elements of the fpath variable.
    # http://zsh.sourceforge.io/Doc/Release/Functions.html#Autoloading-Functions
    autoload -Uz "${XDG_CONFIG_HOME:-$HOME/.config}/bin"/^(.*|*.zwc*)(.:t)
  # }}
# }
