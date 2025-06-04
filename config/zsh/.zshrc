#!/usr/bin/env zsh

# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc
# Contains commands that loads shell options, aliases, functions, key bindings and plugins

# COLORS, TERM & PATH {
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
export LS_COLORS='bd=0;38;2;154;237;254;48;2;51;51;51:su=0:rs=0:cd=0;38;2;255;106;193;48;2;51;51;51:sg=0:mh=0:*~=0;38;2;102;102;102:mi=0;38;2;0;0;0;48;2;255;92;87:ex=1;38;2;255;92;87:do=0;38;2;0;0;0;48;2;255;106;193:ow=0:tw=0:ca=0:or=0;38;2;0;0;0;48;2;255;92;87:so=0;38;2;0;0;0;48;2;255;106;193:pi=0;38;2;0;0;0;48;2;87;199;255:st=0:no=0:ln=0;38;2;255;106;193:fi=0:di=0;38;2;87;199;255:*.p=0;38;2;90;247;142:*.c=0;38;2;90;247;142:*.m=0;38;2;90;247;142:*.a=1;38;2;255;92;87:*.h=0;38;2;90;247;142:*.o=0;38;2;102;102;102:*.d=0;38;2;90;247;142:*.z=4;38;2;154;237;254:*.r=0;38;2;90;247;142:*.t=0;38;2;90;247;142:*.pm=0;38;2;90;247;142:*.hh=0;38;2;90;247;142:*.cr=0;38;2;90;247;142:*.7z=4;38;2;154;237;254:*.nb=0;38;2;90;247;142:*.pp=0;38;2;90;247;142:*css=0;38;2;90;247;142:*.md=0;38;2;243;249;157:*.kt=0;38;2;90;247;142:*.sh=0;38;2;90;247;142:*.js=0;38;2;90;247;142:*.td=0;38;2;90;247;142:*.ps=0;38;2;255;92;87:*.gz=4;38;2;154;237;254:*.di=0;38;2;90;247;142:*.hi=0;38;2;102;102;102:*.cs=0;38;2;90;247;142:*.as=0;38;2;90;247;142:*.hs=0;38;2;90;247;142:*.xz=4;38;2;154;237;254:*.jl=0;38;2;90;247;142:*.vb=0;38;2;90;247;142:*.mn=0;38;2;90;247;142:*.go=0;38;2;90;247;142:*.el=0;38;2;90;247;142:*.bz=4;38;2;154;237;254:*.lo=0;38;2;102;102;102:*.ko=1;38;2;255;92;87:*.bc=0;38;2;102;102;102:*.py=0;38;2;90;247;142:*.cc=0;38;2;90;247;142:*.so=1;38;2;255;92;87:*.rm=0;38;2;255;180;223:*.pl=0;38;2;90;247;142:*.fs=0;38;2;90;247;142:*.ex=0;38;2;90;247;142:*.gv=0;38;2;90;247;142:*.ts=0;38;2;90;247;142:*.rs=0;38;2;90;247;142:*.la=0;38;2;102;102;102:*.rb=0;38;2;90;247;142:*.ml=0;38;2;90;247;142:*.cp=0;38;2;90;247;142:*.ui=0;38;2;243;249;157:*.wv=0;38;2;255;180;223:*.ll=0;38;2;90;247;142:*.tex=0;38;2;90;247;142:*.epp=0;38;2;90;247;142:*.fsx=0;38;2;90;247;142:*.sty=0;38;2;102;102;102:*.mir=0;38;2;90;247;142:*.erl=0;38;2;90;247;142:*.zst=4;38;2;154;237;254:*.eps=0;38;2;255;180;223:*.tml=0;38;2;243;249;157:*.vcd=4;38;2;154;237;254:*.awk=0;38;2;90;247;142:*hgrc=0;38;2;165;255;195:*TODO=1:*.log=0;38;2;102;102;102:*.tgz=4;38;2;154;237;254:*.tmp=0;38;2;102;102;102:*.sbt=0;38;2;90;247;142:*.aif=0;38;2;255;180;223:*.m4v=0;38;2;255;180;223:*.bat=1;38;2;255;92;87:*.fnt=0;38;2;255;180;223:*.bbl=0;38;2;102;102;102:*.tif=0;38;2;255;180;223:*.wmv=0;38;2;255;180;223:*.ipp=0;38;2;90;247;142:*.bin=4;38;2;154;237;254:*.bmp=0;38;2;255;180;223:*.blg=0;38;2;102;102;102:*.exe=1;38;2;255;92;87:*.cxx=0;38;2;90;247;142:*.toc=0;38;2;102;102;102:*.swp=0;38;2;102;102;102:*.dpr=0;38;2;90;247;142:*.deb=4;38;2;154;237;254:*.xlr=0;38;2;255;92;87:*.flv=0;38;2;255;180;223:*.vim=0;38;2;90;247;142:*.htc=0;38;2;90;247;142:*.pid=0;38;2;102;102;102:*.img=4;38;2;154;237;254:*.pod=0;38;2;90;247;142:*.ps1=0;38;2;90;247;142:*.wav=0;38;2;255;180;223:*.pgm=0;38;2;255;180;223:*.bz2=4;38;2;154;237;254:*.xls=0;38;2;255;92;87:*.zsh=0;38;2;90;247;142:*.wma=0;38;2;255;180;223:*.swf=0;38;2;255;180;223:*.avi=0;38;2;255;180;223:*.gvy=0;38;2;90;247;142:*.vob=0;38;2;255;180;223:*.cfg=0;38;2;243;249;157:*.ini=0;38;2;243;249;157:*.psd=0;38;2;255;180;223:*.ogg=0;38;2;255;180;223:*.php=0;38;2;90;247;142:*.iso=4;38;2;154;237;254:*.tar=4;38;2;154;237;254:*.m4a=0;38;2;255;180;223:*.dll=1;38;2;255;92;87:*.cgi=0;38;2;90;247;142:*.com=1;38;2;255;92;87:*.csx=0;38;2;90;247;142:*.ics=0;38;2;255;92;87:*.bib=0;38;2;243;249;157:*.fls=0;38;2;102;102;102:*.jar=4;38;2;154;237;254:*.def=0;38;2;90;247;142:*.sxw=0;38;2;255;92;87:*.arj=4;38;2;154;237;254:*.apk=4;38;2;154;237;254:*.pdf=0;38;2;255;92;87:*.htm=0;38;2;243;249;157:*.doc=0;38;2;255;92;87:*.zip=4;38;2;154;237;254:*.png=0;38;2;255;180;223:*.out=0;38;2;102;102;102:*.dot=0;38;2;90;247;142:*.elm=0;38;2;90;247;142:*.bst=0;38;2;243;249;157:*.lua=0;38;2;90;247;142:*.ods=0;38;2;255;92;87:*.clj=0;38;2;90;247;142:*.dmg=4;38;2;154;237;254:*.xcf=0;38;2;255;180;223:*.tbz=4;38;2;154;237;254:*.hpp=0;38;2;90;247;142:*.pro=0;38;2;165;255;195:*.ilg=0;38;2;102;102;102:*.git=0;38;2;102;102;102:*.pyo=0;38;2;102;102;102:*.tcl=0;38;2;90;247;142:*.rar=4;38;2;154;237;254:*.ppt=0;38;2;255;92;87:*.bcf=0;38;2;102;102;102:*.rtf=0;38;2;255;92;87:*.xml=0;38;2;243;249;157:*.csv=0;38;2;243;249;157:*.pps=0;38;2;255;92;87:*.mp3=0;38;2;255;180;223:*.asa=0;38;2;90;247;142:*.sql=0;38;2;90;247;142:*.fsi=0;38;2;90;247;142:*.ind=0;38;2;102;102;102:*.yml=0;38;2;243;249;157:*.cpp=0;38;2;90;247;142:*.inl=0;38;2;90;247;142:*.mkv=0;38;2;255;180;223:*.ltx=0;38;2;90;247;142:*.idx=0;38;2;102;102;102:*.bak=0;38;2;102;102;102:*.c++=0;38;2;90;247;142:*.bsh=0;38;2;90;247;142:*.kts=0;38;2;90;247;142:*.rst=0;38;2;243;249;157:*.hxx=0;38;2;90;247;142:*.pyc=0;38;2;102;102;102:*.fon=0;38;2;255;180;223:*.gif=0;38;2;255;180;223:*.jpg=0;38;2;255;180;223:*.pas=0;38;2;90;247;142:*.inc=0;38;2;90;247;142:*.sxi=0;38;2;255;92;87:*.rpm=4;38;2;154;237;254:*.svg=0;38;2;255;180;223:*.kex=0;38;2;255;92;87:*.nix=0;38;2;243;249;157:*.mpg=0;38;2;255;180;223:*.mp4=0;38;2;255;180;223:*.ttf=0;38;2;255;180;223:*.exs=0;38;2;90;247;142:*.ppm=0;38;2;255;180;223:*.mov=0;38;2;255;180;223:*.pyd=0;38;2;102;102;102:*.txt=0;38;2;243;249;157:*.mid=0;38;2;255;180;223:*.xmp=0;38;2;243;249;157:*.aux=0;38;2;102;102;102:*.bag=4;38;2;154;237;254:*.tsx=0;38;2;90;247;142:*.mli=0;38;2;90;247;142:*.odt=0;38;2;255;92;87:*.pkg=4;38;2;154;237;254:*.otf=0;38;2;255;180;223:*.pbm=0;38;2;255;180;223:*.odp=0;38;2;255;92;87:*.h++=0;38;2;90;247;142:*.dox=0;38;2;165;255;195:*.ico=0;38;2;255;180;223:*.html=0;38;2;243;249;157:*.mpeg=0;38;2;255;180;223:*.bash=0;38;2;90;247;142:*.lisp=0;38;2;90;247;142:*.opus=0;38;2;255;180;223:*.h264=0;38;2;255;180;223:*.yaml=0;38;2;243;249;157:*.diff=0;38;2;90;247;142:*.docx=0;38;2;255;92;87:*.webm=0;38;2;255;180;223:*.tiff=0;38;2;255;180;223:*.orig=0;38;2;102;102;102:*.java=0;38;2;90;247;142:*.jpeg=0;38;2;255;180;223:*.make=0;38;2;165;255;195:*.tbz2=4;38;2;154;237;254:*.rlib=0;38;2;102;102;102:*.hgrc=0;38;2;165;255;195:*.pptx=0;38;2;255;92;87:*.xlsx=0;38;2;255;92;87:*.toml=0;38;2;243;249;157:*.lock=0;38;2;102;102;102:*.conf=0;38;2;243;249;157:*.flac=0;38;2;255;180;223:*.psm1=0;38;2;90;247;142:*.less=0;38;2;90;247;142:*.purs=0;38;2;90;247;142:*.epub=0;38;2;255;92;87:*.dart=0;38;2;90;247;142:*.psd1=0;38;2;90;247;142:*.json=0;38;2;243;249;157:*.fish=0;38;2;90;247;142:*README=0;38;2;40;42;54;48;2;243;249;157:*.class=0;38;2;102;102;102:*.cabal=0;38;2;90;247;142:*.dyn_o=0;38;2;102;102;102:*.ipynb=0;38;2;90;247;142:*.patch=0;38;2;90;247;142:*.xhtml=0;38;2;243;249;157:*.cache=0;38;2;102;102;102:*shadow=0;38;2;243;249;157:*.shtml=0;38;2;243;249;157:*.scala=0;38;2;90;247;142:*.swift=0;38;2;90;247;142:*.toast=4;38;2;154;237;254:*passwd=0;38;2;243;249;157:*.mdown=0;38;2;243;249;157:*.cmake=0;38;2;165;255;195:*.flake8=0;38;2;165;255;195:*.groovy=0;38;2;90;247;142:*.config=0;38;2;243;249;157:*.gradle=0;38;2;90;247;142:*.dyn_hi=0;38;2;102;102;102:*LICENSE=0;38;2;153;153;153:*COPYING=0;38;2;153;153;153:*INSTALL=0;38;2;40;42;54;48;2;243;249;157:*TODO.md=1:*.matlab=0;38;2;90;247;142:*.ignore=0;38;2;165;255;195:*.desktop=0;38;2;243;249;157:*.gemspec=0;38;2;165;255;195:*Makefile=0;38;2;165;255;195:*setup.py=0;38;2;165;255;195:*Doxyfile=0;38;2;165;255;195:*TODO.txt=1:*.DS_Store=0;38;2;102;102;102:*.fdignore=0;38;2;165;255;195:*.kdevelop=0;38;2;165;255;195:*README.md=0;38;2;40;42;54;48;2;243;249;157:*configure=0;38;2;165;255;195:*.markdown=0;38;2;243;249;157:*.cmake.in=0;38;2;165;255;195:*COPYRIGHT=0;38;2;153;153;153:*.rgignore=0;38;2;165;255;195:*.gitignore=0;38;2;165;255;195:*CODEOWNERS=0;38;2;165;255;195:*.gitconfig=0;38;2;165;255;195:*SConstruct=0;38;2;165;255;195:*.localized=0;38;2;102;102;102:*Dockerfile=0;38;2;243;249;157:*.scons_opt=0;38;2;102;102;102:*INSTALL.md=0;38;2;40;42;54;48;2;243;249;157:*.synctex.gz=0;38;2;102;102;102:*Makefile.am=0;38;2;165;255;195:*INSTALL.txt=0;38;2;40;42;54;48;2;243;249;157:*Makefile.in=0;38;2;102;102;102:*.gitmodules=0;38;2;165;255;195:*MANIFEST.in=0;38;2;165;255;195:*LICENSE-MIT=0;38;2;153;153;153:*.travis.yml=0;38;2;90;247;142:*.fdb_latexmk=0;38;2;102;102;102:*configure.ac=0;38;2;165;255;195:*appveyor.yml=0;38;2;90;247;142:*CONTRIBUTORS=0;38;2;40;42;54;48;2;243;249;157:*.applescript=0;38;2;90;247;142:*.clang-format=0;38;2;165;255;195:*CMakeLists.txt=0;38;2;165;255;195:*.gitattributes=0;38;2;165;255;195:*LICENSE-APACHE=0;38;2;153;153;153:*CMakeCache.txt=0;38;2;102;102;102:*CONTRIBUTORS.md=0;38;2;40;42;54;48;2;243;249;157:*.sconsign.dblite=0;38;2;102;102;102:*requirements.txt=0;38;2;165;255;195:*CONTRIBUTORS.txt=0;38;2;40;42;54;48;2;243;249;157:*package-lock.json=0;38;2;102;102;102:*.CFUserTextEncoding=0;38;2;102;102;102'

# ZSH/ZIM ESSENTIAL VARIABLES
export ZDOTDIR=${ZDOTDIR:="$HOME/.config/zsh"}
export ZIM_HOME=${ZIM_HOME:="$HOME/.local/state/zim"}
export ZSH_CACHE_DIR=${ZSH_CACHE_DIR:="$HOME/.cache/zsh"}

# The optimal sequence for setting up ZSH & ZIM in .zshrc should be:
# 1. Environment Variables and Parameters
# 2. Completion Settings
# 3. ZIM Setup
# 4. Additional ZSH options
# 5. Post-init ZIM module configuration
# 6. Plugin loading

# ZSH ENVIRONMENT VARIABLES and PARAMETERS (PATH, FPATH, etc.) {
# PATH {
# set PATH so it includes user's private bin if it exists
declare -gaU path=(
  $XDG_BIN_HOME
  $path
)
# }

# FPATH {
# Where the shell searches to find shell functions
declare -gaU fpath=(
  $fpath
)
# }

# CDPATH {
# Directories that the shell searches to find the current directory when the user changes directories using the cd command
declare -gaU cdpath=(
  "$HOME"
  "$ZDOTDIR"
  $cdpath
)
# }

# MANPATH {
export -a manpath=(
  "${manpath[@]}"
)
# }

# PROMPTING {
# General ZSH's parameters related to prompt
# http://zsh.sourceforge.io/Doc/Release/Parameters.html
export PROMPT='❯ '          # default prompt
export ZLE_RPROMPT_INDENT=0 # If set, used to give the indentation between the right hand side of the right prompt in the line editor as given by RPS1 or RPROMPT and the right hand side of the screen. If not set, the value 1 is used. See https://superuser.com/a/726509/389767
# }

# ZSH OPTIONS {
# Some generic Zsh built-in environment options are set by ZIM (https://github.com/zimfw/zimfw)
# Add these to your .zshrc after the ZIM initialization block to ensure proper loading order
# More: https://github.com/zimfw/environment

# EXPANSION-AND-GLOBBING | http://zsh.sourceforge.io/Doc/Release/Options.html#Expansion-and-Globbing
setopt bad_pattern       # Reports bad patterns during globbing => `[[ 1 = 2 ]]` will print an error
setopt brace_ccl         # Enables brace character class lists expansion => `echo {a..z}` will print `abcdefghijklmnopqrstuvwxyz`
setopt numeric_glob_sort # Natural number sorting | Sort filenames numerically when it makes sense => `ls file*` shows: file1 file2 file10 (rather than file1 file10 file2)
# setopt extended_glob          # [SET BY ZIM!!] Advanced pattern matching. I.E.: `rm -rf ^*.txt` removes everything except `.txt` files whereas `ls **/*.{jpg,png}` recursively find images
# setopt mark_dirs              # Add a trailing `/` to all directory names resulting from filename expansion => `echo *.txt` will print `*.txt/`
# setopt nomatch                # [SET BY ZIM!!] Shows error instead of keeping pattern when no matches found => `ls *.nonexistent` shows error instead of keeping pattern
# }

# HISTORY | http://zsh.sourceforge.io/Doc/Release/Options.html#History
setopt bang_hist              # Treat the `!` character specially during expansion => `!ls` will execute `ls`
setopt extended_history       # Save each command's beginning timestamp and the duration => `history` will print `beginning_timestamp duration command`
setopt hist_expire_dups_first # When trimming history, remove duplicates and commands that begin with a space => `history -c` will remove duplicates and commands that begin with a space
setopt hist_ignore_all_dups   # When trimming history, remove duplicates => `history -c` will remove duplicates
setopt hist_reduce_blanks     # Remove superfluous blanks from each command line being added to the history list => `history -c` will remove superfluous blanks
setopt hist_subst_pattern     # Perform pattern substitution on history expansion => `history -c` will perform pattern substitution on history expansion
# setopt hist_verify            # [SET BY ZIM!!] When using history substitution, put the expanded command in the edit buffer instead of executing it => `history -c` will execute the expanded command
# setopt share_history          # [SET BY ZIM!!] Share history between all sessions => `history -c` will share history between all sessions
# }

# INPUT OUTPUT | http://zsh.sourceforge.io/Doc/Release/Options.html#Input_002fOutput
setopt hash_cmds   # Improves command execution speed | Keep hash table of commands for faster execution => First run is slower as path is hashed: `ls -l /usr/bin/ls  # ~100ms`. Subsequent runs are faster using hash table: `ls -l /usr/bin/ls  # ~10ms`
setopt hash_dirs   # Improves command execution speed | Keep hash table of directories for faster execution => First run is slower as path is hashed: `ls /usr/local/bin  # ~100ms`. Subsequent runs are faster using hash table: `ls /usr/local/bin  # ~10ms`
setopt path_dirs   # Improves command execution speed | Perform path search even on command names with slashes => `ls -l /usr/bin/ls` will print `/usr/bin/ls`
setopt rc_quotes   # Easier string handling | Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'
setopt short_loops # Shorter one-line loops | Enable shortened loop syntax => It allows `for i in *; echo $i` to be used instead of `for i in *; do echo $i; done`
# setopt aliases                # [SET BY ZIM!!] Expand aliases => `alias ls='echo ls'` will expand `ls` to `echo ls`
# setopt clobber                # [SET BY ZIM!!] Allow the > operator to truncate existing files, and redirect all output to a file when the file exists => `ls -l /usr/bin/ls > ls.txt` will truncate `ls.txt` and redirect all output to it
# setopt interactive_comments   # [SET BY ZIM!!] Better script documentation and command explanation | Allow comments even in interactive shells => `# hello world` will print `# hello world`
# setopt no_mail_warning        # [SET BY ZIM!!] Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
# }

# PROMPTING | http://zsh.sourceforge.io/Doc/Release/Options.html#Prompting
setopt transient_rprompt # Reduces notification noise | Do not print a warning message if a mail file has been accessed => `mail` will not print a warning message if a mail file has been accessed
# setopt prompt_subst           # [SET BY ZIM!!] Allow substitution in the prompt => `PS1='$(date)'` will print the current date in the prompt
# }

# SCRIPTS AND FUNCTIONS | http://zsh.sourceforge.io/Doc/Release/Options.html#Scripts-and-Functions
setopt alias_func_def    # Advanced shell customization | Allows alias and function with same name => `alias ls='ls --color=auto'` and `function ls() { command ls --color=auto "$@" }` will work
setopt bsd_echo          # Cross-platform scripts | Makes echo behave like BSD echo => `echo "Hello\nWorld"` prints literal `\n` whereas `echo -e "Hello\nWorld"` prints on two lines
setopt sh_file_expansion # sh-compatibility needs | Makes file expansion sh-compatible => `ls !(*.txt)` will list all files except those with the .txt extension
setopt typeset_silent    # Cleaner script output | Suppresses typeset command output => `typeset -A myarray` will not print `myarray`
# setopt multios                # [SET BY ZIM!!] Advanced I/O operations | Enable multiple redirections => `echo "test" > file1 > file2` writes to both whereas `cat < file1 < file2` reads from both
# }

# JOB CONTROL | http://zsh.sourceforge.io/Doc/Release/Options.html#Job-Control
setopt auto_resume # Resume background jobs automatically | Resume background jobs automatically => `ls &` will resume the job even if the shell is closed
# setopt long_list_jobs         # [SET BY ZIM!!] Better job listing | List jobs in the long format by default => `jobs` will list jobs in the long format by default
# }

# ZLE | http://zsh.sourceforge.io/Doc/Release/Options.html#Zle
setopt combining_chars # Multilingual text handling | Handles Unicode combining characters => `echo "e\u0301"` outputs: é
setopt no_beep         # Reduces notification noise | Silences beeps on tab completion errors => `ls -l /usr/bin/ls` will not print a beep when tab completing
setopt no_flow_control # Disables ^S/^Q flow control | Frees up ^S for history search and ^Q for exiting the shell => `C-q` will not suspend the shell
# setopt no_list_beep           # [SET BY ZIM!!] Reduces notification noise | Disables beep in completion lists and Silences beeps during tab completion => `ls -l /usr/bin/ls` will not print a beep when tab completing
# }

# COMPLETIONS | http://zsh.sourceforge.io/Doc/Release/Options.html#Completion-4 {
setopt auto_list        # Completion Navigation | Automatically list choices on ambiguous completion.
setopt auto_menu        # Completion Navigation | Automatically show completion menu on successive tab.
setopt auto_param_keys  # Parameter Completion | Intelligently add space after = or :.
setopt auto_param_slash # Parameter Completion | Automatically insert a slash when completing a directory
setopt complete_in_word # Completion Navigation | Complete from both ends of a word.
setopt glob_dots        # Globbing | Include dotfiles in globbing
setopt list_ambiguous   # Completion Navigation | Show unambiguous prefix first
# setopt always_to_end          # [SET BY ZIM!!] Completion Navigation | Cursor moves to end after completion.
# setopt no_case_glob           # [SET BY ZIM!!] Globbing | Case insensitive globbing.
# }

# https://no-color.org
unset NO_COLOR

# ZIM SETUP | https://zimfw.sh {
# The Zsh configuration framework with blazing speed and modular extensions.
# https://zimfw.sh

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

# Initialize modules.
if [[ -f $ZIM_HOME/init.zsh ]]; then
  source $ZIM_HOME/init.zsh
fi
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
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh}/compcache"          # Cache path
zstyle ':completion::complete:*' rehash yes                                                                  # Rehash
zstyle ':completion:*:functions' ignored-patterns '_*'                                                       # Ignore internal functions
zstyle ':completion::complete:*' gain-privileges 1                                                           # Gain privileges
zstyle ':completion:*:match:*' original only                                                                 # Match original only
zstyle ':completion:*:corrections' format '%B%F{green} -- %d --%f%F{magenta}(errors: %e)%f%b'                # Corrections format
zstyle ':completion:*:*:cd:*' tag-order local-directories named-directories directory-stack path-directories # CD tag order
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'         # Tilde group order
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $LOGNAME -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*:*:*:*:processes' command 'ps -u $LOGNAME -o pid,user,comm -w'                                      # Processes command
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3>7?7:($#PREFIX+$#SUFFIX)/3))numeric)' # Max errors
# }

# STARSHIP {
# The minimal, blazing-fast, and infinitely customizable prompt for any shell!
# https://starship.rs/config/#configuration
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG_HOME=$XDG_CONFIG_HOME/starship
  export STARSHIP_CONFIG=$STARSHIP_CONFIG_HOME/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
fi
# }

# [N]VIM {
# +BundleInstall +qall, Install all vim bundles
# https://superuser.com/a/874924/389767
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=$(command -v nvim)
  export VIM_PATH=$XDG_CONFIG_HOME/nvim
  export MYVIMRC=$VIM_PATH/init.lua
  export NVIM_LOG_FILE=$XDG_CACHE_HOME/nvim/.nvimlog
  alias vim=nvim
  alias vi=nvim
else
  export EDITOR=$(command -v vim || command -v vi)
  alias vi=vim
fi
# }

# EDITOR {
export VISUAL=$EDITOR
export SUDO_EDITOR=$EDITOR
export GIT_EDITOR="$EDITOR -c 'startinsert'"
export LAUNCH_EDITOR=$EDITOR
# }

# ZPROF {
# profilling
if [[ -n "$z_prof" ]]; then
  if [[ -n "$z_trace" ]]; then
    unsetopt XTRACE
    exec 2>&3 3>&-
    zprof >$HOME/.config/zsh/tmp/benchmark.$$.prof.log
  else
    zprof
  fi
  zmodload -u zsh/zprof
elif [[ -n "$z_trace" ]]; then
  unsetopt XTRACE
fi
# }
