#!/usr/bin/env zsh
# Colour palette: LS_COLORS, EXA_COLORS and the fast-syntax-highlighting theme.
# Loaded by .zshrc; defines functions only — nothing runs at load time.
#DECLARES theme::palette

#ABOUT Define terminal colour and syntax-highlight palettes.
#ORDER Before ZIM: fast-syntax-highlighting reads FAST_HIGHLIGHT_STYLES at load.
theme::palette() {
  export DIRSTACKSIZE=${DIRSTACKSIZE:-100}
  export PAGER=${PAGER:-"less -FREXi"}
  export BROWSER=${BROWSER:-"open"}
  export MANROFFOPT=${MANROFFOPT:-"-c"}
  export CLICOLOR=${CLICOLOR:-1}
  export LSCOLORS=EgCeDdEeCcghhahahacac
  export LS_COLORS="di=0;38;2;122;162;247:ln=0;38;2;42;195;222:ex=1;38;2;158;206;106:fi=0;38;2;192;202;245:pi=0;38;2;65;72;104:so=0;38;2;65;72;104:bd=0;38;2;224;175;104:cd=0;38;2;224;175;104:su=0;38;2;255;0;124:sg=0;38;2;255;0;124:tw=0;38;2;255;0;124:ow=0;38;2;255;0;124:st=0;38;2;255;0;124:mi=0;38;2;157;124;216:or=0;38;2;157;124;216:*.c=0;38;2;158;206;106:*.h=0;38;2;158;206;106:*.cpp=0;38;2;158;206;106:*.hpp=0;38;2;158;206;106:*.cc=0;38;2;158;206;106:*.cxx=0;38;2;158;206;106:*.py=0;38;2;158;206;106:*.js=0;38;2;158;206;106:*.ts=0;38;2;158;206;106:*.tsx=0;38;2;158;206;106:*.jsx=0;38;2;158;206;106:*.rs=0;38;2;158;206;106:*.go=0;38;2;158;206;106:*.java=0;38;2;158;206;106:*.kt=0;38;2;158;206;106:*.swift=0;38;2;158;206;106:*.rb=0;38;2;158;206;106:*.php=0;38;2;158;206;106:*.pl=0;38;2;158;206;106:*.sh=0;38;2;158;206;106:*.bash=0;38;2;158;206;106:*.zsh=0;38;2;158;206;106:*.fish=0;38;2;158;206;106:*.lua=0;38;2;158;206;106:*.vim=0;38;2;158;206;106:*.el=0;38;2;158;206;106:*.clj=0;38;2;158;206;106:*.hs=0;38;2;158;206;106:*.ml=0;38;2;158;206;106:*.fs=0;38;2;158;206;106:*.fsx=0;38;2;158;206;106:*.fsi=0;38;2;158;206;106:*.dart=0;38;2;158;206;106:*.scala=0;38;2;158;206;106:*.groovy=0;38;2;158;206;106:*.gradle=0;38;2;158;206;106:*.sbt=0;38;2;158;206;106:*.kts=0;38;2;158;206;106:*.sql=0;38;2;158;206;106:*.r=0;38;2;158;206;106:*.jl=0;38;2;158;206;106:*.cr=0;38;2;158;206;106:*.ex=0;38;2;158;206;106:*.exs=0;38;2;158;206;106:*.cs=0;38;2;158;206;106:*.vb=0;38;2;158;206;106:*.pas=0;38;2;158;206;106:*.dpr=0;38;2;158;206;106:*.inc=0;38;2;158;206;106:*.asm=0;38;2;158;206;106:*.s=0;38;2;158;206;106:*.S=0;38;2;158;206;106:*.ll=0;38;2;158;206;106:*.bc=0;38;2;158;206;106:*.mir=0;38;2;158;206;106:*.erl=0;38;2;158;206;106:*.hrl=0;38;2;158;206;106:*.app.src=0;38;2;158;206;106:*.app=0;38;2;158;206;106:*.appup=0;38;2;158;206;106:*.rel=0;38;2;158;206;106:*.config=0;38;2;42;195;222:*.conf=0;38;2;42;195;222:*.cfg=0;38;2;42;195;222:*.ini=0;38;2;42;195;222:*.toml=0;38;2;42;195;222:*.yaml=0;38;2;42;195;222:*.yml=0;38;2;42;195;222:*.json=0;38;2;42;195;222:*.xml=0;38;2;42;195;222:*.html=0;38;2;42;195;222:*.htm=0;38;2;42;195;222:*.css=0;38;2;42;195;222:*.scss=0;38;2;42;195;222:*.sass=0;38;2;42;195;222:*.less=0;38;2;42;195;222:*.md=0;38;2;122;162;247:*.markdown=0;38;2;122;162;247:*.rst=0;38;2;122;162;247:*.tex=0;38;2;122;162;247:*.ltx=0;38;2;122;162;247:*.sty=0;38;2;122;162;247:*.cls=0;38;2;122;162;247:*.bib=0;38;2;122;162;247:*.bst=0;38;2;122;162;247:*.dot=0;38;2;122;162;247:*.gv=0;38;2;122;162;247:*.ui=0;38;2;122;162;247:*.glade=0;38;2;122;162;247:*.desktop=0;38;2;122;162;247:*.service=0;38;2;122;162;247:*.timer=0;38;2;122;162;247:*.socket=0;38;2;122;162;247:*.target=0;38;2;122;162;247:*.mount=0;38;2;180;249;248:*.automount=0;38;2;180;249;248:*.swap=0;38;2;180;249;248:*.path=0;38;2;180;249;248:*.slice=0;38;2;180;249;248:*.scope=0;38;2;180;249;248:*.nix=0;38;2;42;195;222:*.flake=0;38;2;42;195;222:*.lock=0;38;2;42;195;222:*.gitignore=0;38;2;42;195;222:*.gitattributes=0;38;2;42;195;222:*.gitmodules=0;38;2;42;195;222:*.gitconfig=0;38;2;42;195;222:*.hgrc=0;38;2;42;195;222:*.hgignore=0;38;2;42;195;222:*.svnignore=0;38;2;42;195;222:*.bzrignore=0;38;2;42;195;222:*.cvsignore=0;38;2;42;195;222:*.dockerignore=0;38;2;42;195;222:*.fdignore=0;38;2;42;195;222:*.rgignore=0;38;2;42;195;222:*.ignore=0;38;2;42;195;222:*.editorconfig=0;38;2;42;195;222:"
  export EXA_COLORS="di=1;38;2;122;162;247:ex=01;38;5;10:fi=0;38;2;192;202;245:pi=2;38;2;65;72;104:so=3;38;2;65;72;104:bd=4;38;2;224;175;104:cd=0;38;2;224;175;104:ln=04;01;38;5;205:or=0;38;2;157;124;216:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
  # FAST-SYNTAX-HIGHLIGHTING | https://github.com/zdharma-continuum/fast-syntax-highlighting/blob/master/THEME_GUIDE.md
  # fast-theme -p
  typeset -gA FAST_HIGHLIGHT_STYLES
  # Basic styles
  FAST_HIGHLIGHT_STYLES[default]='none'
  FAST_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'              # Red (error)
  FAST_HIGHLIGHT_STYLES[reserved-word]='fg=180'                   # Peach
  # Commands and functions
  FAST_HIGHLIGHT_STYLES[alias]='fg=green,bold'                    # Green (distinctive)
  FAST_HIGHLIGHT_STYLES[suffix-alias]='fg=green'                  # Green
  FAST_HIGHLIGHT_STYLES[builtin]='fg=green,bold'                  # Green bold
  FAST_HIGHLIGHT_STYLES[function]='fg=green,bold,italic'          # Green bold italic
  FAST_HIGHLIGHT_STYLES[command]='fg=green,bold'                  # Green (main commands)
  FAST_HIGHLIGHT_STYLES[precommand]='fg=147,italic'               # Purple italic
  FAST_HIGHLIGHT_STYLES[commandseparator]='fg=186'                # Overlay2 (subtle)
  FAST_HIGHLIGHT_STYLES[hashed-command]='fg=green'                # Green
  FAST_HIGHLIGHT_STYLES[subcommand]='fg=147,bold'                 # Purple bold
  # Paths and files
  FAST_HIGHLIGHT_STYLES[path]='fg=cyan,underline'                 # Cyan underline
  FAST_HIGHLIGHT_STYLES[path_pathseparator]='fg=cyan,underline'   # Cyan underline
  FAST_HIGHLIGHT_STYLES[path-to-dir]='fg=cyan,bold,underline'     # Cyan bold underlined
  FAST_HIGHLIGHT_STYLES[globbing]='fg=219,bold'                   # Pink bold
  FAST_HIGHLIGHT_STYLES[globbing-ext]='fg=219'                    # Pink
  # Special expansions
  FAST_HIGHLIGHT_STYLES[history-expansion]='fg=219,bold'          # Pink bold
  # Options
  FAST_HIGHLIGHT_STYLES[single-hyphen-option]='fg=105,bold'       # Purple Bright bold
  FAST_HIGHLIGHT_STYLES[double-hyphen-option]='fg=105,bold'       # Purple Bright bold
  FAST_HIGHLIGHT_STYLES[optarg-string]='fg=044'                   # Green
  FAST_HIGHLIGHT_STYLES[optarg-number]='fg=051'                   # Lavender
  # Strings and arguments
  FAST_HIGHLIGHT_STYLES[back-quoted-argument]='fg=011'            # Yellow
  FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=011'          # Yellow
  FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=011'          # Yellow
  FAST_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=011'          # Yellow
  FAST_HIGHLIGHT_STYLES[back-or-dollar-double-quoted-argument]='fg=011' # Yellow
  FAST_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=011'     # Yellow
  # Variables and math
  FAST_HIGHLIGHT_STYLES[assign]='fg=219'                          # Pink
  FAST_HIGHLIGHT_STYLES[variable]='fg=153'                        # Lavender
  FAST_HIGHLIGHT_STYLES[mathvar]='fg=cyan'                        # Cyan
  FAST_HIGHLIGHT_STYLES[mathnum]='fg=245'                         # Peach (numbers)
  FAST_HIGHLIGHT_STYLES[matherr]='fg=red,bold'                    # Red bold
  FAST_HIGHLIGHT_STYLES[assign-array-bracket]='fg=186'            # Overlay2
  # Control flow
  FAST_HIGHLIGHT_STYLES[for-loop-variable]='fg=153'               # Lavender
  FAST_HIGHLIGHT_STYLES[for-loop-number]='fg=245'                 # Peach
  FAST_HIGHLIGHT_STYLES[for-loop-operator]='fg=186'               # Overlay2
  FAST_HIGHLIGHT_STYLES[for-loop-separator]='fg=186,bold'         # Overlay2 bold
  # Redirection and descriptors
  FAST_HIGHLIGHT_STYLES[redirection]='fg=219'                     # Pink
  FAST_HIGHLIGHT_STYLES[exec-descriptor]='fg=blue,bold'           # Blue bold
  # Here strings
  FAST_HIGHLIGHT_STYLES[here-string-tri]='fg=186'                 # Overlay2
  FAST_HIGHLIGHT_STYLES[here-string-text]='fg=115'                # Green
  FAST_HIGHLIGHT_STYLES[here-string-var]='fg=153'                 # Lavender
  # Comments
  FAST_HIGHLIGHT_STYLES[comment]='fg=242,italic'                  # Surface2 (gray) italic
  # Case statements
  FAST_HIGHLIGHT_STYLES[case-input]='fg=153'                      # Lavender
  FAST_HIGHLIGHT_STYLES[case-parentheses]='fg=186'                # Overlay2
  FAST_HIGHLIGHT_STYLES[case-condition]='fg=blue'                 # Blue
  # Corrections
  FAST_HIGHLIGHT_STYLES[correct-subtle]='fg=115'                  # Green
  FAST_HIGHLIGHT_STYLES[incorrect-subtle]='fg=red'                # Red
  # Subtle elements
  FAST_HIGHLIGHT_STYLES[subtle-separator]='fg=186'                # Overlay2
  FAST_HIGHLIGHT_STYLES[subtle-bg]='bg=none'                      # None
  FAST_HIGHLIGHT_STYLES[secondary]='fg=186'                       # Overlay2
  # Brackets and parentheses
  FAST_HIGHLIGHT_STYLES[paired-bracket]='fg=186,bold'             # Overlay2 bold
  FAST_HIGHLIGHT_STYLES[bracket-level-1]='fg=051'                 # Orange
  FAST_HIGHLIGHT_STYLES[bracket-level-2]='fg=245'                 # Peach
  FAST_HIGHLIGHT_STYLES[bracket-level-3]='fg=219'                 # Pink
  FAST_HIGHLIGHT_STYLES[single-sq-bracket]='fg=186'               # Overlay2
  FAST_HIGHLIGHT_STYLES[double-sq-bracket]='fg=186'               # Overlay2
  FAST_HIGHLIGHT_STYLES[double-paren]='fg=051'                    # Orange
  # Aliases
  FAST_HIGHLIGHT_STYLES[global-alias]='fg=194,bold'               # Green Bright bold
  # Recursive
  FAST_HIGHLIGHT_STYLES[recursive-base]='none'
}

theme::palette
