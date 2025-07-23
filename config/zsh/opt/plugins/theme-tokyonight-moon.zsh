# ===============================================================================
# LSCOLORS, LS_COLORS and EXA_COLORS CONFIGURATION
# ===============================================================================

# Palette (from eza theme):
# normal:      #c0caf5
# directory:   #7aa2f7
# symlink:     #2ac3de
# pipe:        #414868
# block/char:  #e0af68
# socket:      #414868
# special:     #9d7cd8
# executable:  #9ece6a
# mount_point: #b4f9f8

# LSCOLORS for macOS (BSD ls)
# ===============================================================================
# ORDER
# [dir][sym][exe][blk][chr][sok][pipe][suid][sgid][dirw/sticky][dirw/nstky][exe/suid][exe/sgid][dirw/stky][dirw/nstky][exe/suid][exe/sgid][dirw/stky][dirw/nstky][exe/suid]
#
# COLOR CODES
# a = black, b = red, c = green, d = brown, e = blue, f = magenta, g = cyan, h = light grey
# A = bold black, B = bold red, C = bold green, D = bold brown, E = bold blue, F = bold magenta, G = bold cyan, H = bold light grey, x = default
#
# COLORS
# black = #292e42
# red = #db4b4b
# green = #9ece6a
# brown/yellow = #e0af68
# blue = #3d59a1
# magenta = #9d7cd8
# cyan = #2ac3de
# light grey = #c0caf5
# bold black = #292e42
# bold red = #af3232
# bold green = #96DA5D
# bold brown/yellow = #daa14a
# bold blue = #7aa2f7
# bold magenta = #bb9af7
# bold cyan = #89ddff
# bold light grey = #a9b1d6
# default = #c0caf5
# ===============================================================================
export LSCOLORS=EgCeDdEeCcghhahahacac

# LS_COLORS for GNU ls (Linux)
# ===============================================================================
# LS_COLORS Key/Color Table
#
# Key/Pattern         | Value                 | Hex Color | Palette Name/Usage
# --------------------|-----------------------|-----------|---------------------
# di                  | 0;38;2;122;162;247    | #7aa2f7   | Blue (directory)
# ln                  | 0;38;2;42;195;222     | #2ac3de   | Cyan (symlink)
# ex                  | 1;38;2;158;206;106    | #9ece6a   | Green (executable, bold)
# fi                  | 0;38;2;192;202;245    | #c0caf5   | Light blue (regular file)
# pi,so               | 0;38;2;65;72;104      | #414868   | Grey/blue (pipe/socket)
# bd,cd               | 0;38;2;224;175;104    | #e0af68   | Yellow (block/char device)
# su,sg,tw,ow,st      | 0;38;2;255;0;124      | #ff007c   | Pink/red (special perms)
# mi,or               | 0;38;2;157;124;216    | #9d7cd8   | Purple (missing/orphan)
# *.c,*.py,*.sh, etc. | 0;38;2;158;206;106    | #9ece6a   | Green (source code)
# *.yml,*.yaml,*.json | 0;38;2;42;195;222     | #2ac3de   | Cyan (config/data)
# *.md,*.markdown     | 0;38;2;122;162;247    | #7aa2f7   | Blue (docs)
# *.mount,*.automount | 0;38;2;180;249;248    | #b4f9f8   | Aqua (mount points)
# ...                 | ...                   | ...       | ...
#
# ===============================================================================
# Each key (e.g., *.yml, di, ex, etc.) is assigned a value that controls the color and style.
# The value format is: 0 = normal, 1 = bold, 4 = underline, etc.
# 38;2;R;G;B = set foreground to truecolor RGB
# 48;2;R;G;B = set background to truecolor RGB
# Example:
# When: *.yml=0;38;2;42;195;222
# Then: 0 = normal (not bold, not underlined, etc.)
# And: 38;2;42;195;222 = foreground color: RGB(42, 195, 222)
# And: RGB(42, 195, 222) is the color #2ac3de (cyan in the Tokyonight palette)
# To convert: 38;2;R;G;B → #RRGGBB (hex)
# Example: 38;2;42;195;222 → #2ac3de
# Example: 0;38;2;42;195;222 → #2ac3de (no bold)
# ===============================================================================
export LS_COLORS='di=0;38;2;122;162;247:ln=0;38;2;42;195;222:ex=1;38;2;158;206;106:fi=0;38;2;192;202;245:pi=0;38;2;65;72;104:so=0;38;2;65;72;104:bd=0;38;2;224;175;104:cd=0;38;2;224;175;104:su=0;38;2;255;0;124:sg=0;38;2;255;0;124:tw=0;38;2;255;0;124:ow=0;38;2;255;0;124:st=0;38;2;255;0;124:mi=0;38;2;157;124;216:or=0;38;2;157;124;216:*.c=0;38;2;158;206;106:*.h=0;38;2;158;206;106:*.cpp=0;38;2;158;206;106:*.hpp=0;38;2;158;206;106:*.cc=0;38;2;158;206;106:*.cxx=0;38;2;158;206;106:*.py=0;38;2;158;206;106:*.js=0;38;2;158;206;106:*.ts=0;38;2;158;206;106:*.tsx=0;38;2;158;206;106:*.jsx=0;38;2;158;206;106:*.rs=0;38;2;158;206;106:*.go=0;38;2;158;206;106:*.java=0;38;2;158;206;106:*.kt=0;38;2;158;206;106:*.swift=0;38;2;158;206;106:*.rb=0;38;2;158;206;106:*.php=0;38;2;158;206;106:*.pl=0;38;2;158;206;106:*.sh=0;38;2;158;206;106:*.bash=0;38;2;158;206;106:*.zsh=0;38;2;158;206;106:*.fish=0;38;2;158;206;106:*.lua=0;38;2;158;206;106:*.vim=0;38;2;158;206;106:*.el=0;38;2;158;206;106:*.clj=0;38;2;158;206;106:*.hs=0;38;2;158;206;106:*.ml=0;38;2;158;206;106:*.fs=0;38;2;158;206;106:*.fsx=0;38;2;158;206;106:*.fsi=0;38;2;158;206;106:*.dart=0;38;2;158;206;106:*.scala=0;38;2;158;206;106:*.groovy=0;38;2;158;206;106:*.gradle=0;38;2;158;206;106:*.sbt=0;38;2;158;206;106:*.kts=0;38;2;158;206;106:*.sql=0;38;2;158;206;106:*.r=0;38;2;158;206;106:*.jl=0;38;2;158;206;106:*.cr=0;38;2;158;206;106:*.ex=0;38;2;158;206;106:*.exs=0;38;2;158;206;106:*.cs=0;38;2;158;206;106:*.vb=0;38;2;158;206;106:*.pas=0;38;2;158;206;106:*.dpr=0;38;2;158;206;106:*.inc=0;38;2;158;206;106:*.asm=0;38;2;158;206;106:*.s=0;38;2;158;206;106:*.S=0;38;2;158;206;106:*.ll=0;38;2;158;206;106:*.bc=0;38;2;158;206;106:*.mir=0;38;2;158;206;106:*.erl=0;38;2;158;206;106:*.hrl=0;38;2;158;206;106:*.app.src=0;38;2;158;206;106:*.app=0;38;2;158;206;106:*.appup=0;38;2;158;206;106:*.rel=0;38;2;158;206;106:*.config=0;38;2;42;195;222:*.conf=0;38;2;42;195;222:*.cfg=0;38;2;42;195;222:*.ini=0;38;2;42;195;222:*.toml=0;38;2;42;195;222:*.yaml=0;38;2;42;195;222:*.yml=0;38;2;42;195;222:*.json=0;38;2;42;195;222:*.xml=0;38;2;42;195;222:*.html=0;38;2;42;195;222:*.htm=0;38;2;42;195;222:*.css=0;38;2;42;195;222:*.scss=0;38;2;42;195;222:*.sass=0;38;2;42;195;222:*.less=0;38;2;42;195;222:*.md=0;38;2;122;162;247:*.markdown=0;38;2;122;162;247:*.rst=0;38;2;122;162;247:*.tex=0;38;2;122;162;247:*.ltx=0;38;2;122;162;247:*.sty=0;38;2;122;162;247:*.cls=0;38;2;122;162;247:*.bib=0;38;2;122;162;247:*.bst=0;38;2;122;162;247:*.dot=0;38;2;122;162;247:*.gv=0;38;2;122;162;247:*.ui=0;38;2;122;162;247:*.glade=0;38;2;122;162;247:*.desktop=0;38;2;122;162;247:*.service=0;38;2;122;162;247:*.timer=0;38;2;122;162;247:*.socket=0;38;2;122;162;247:*.target=0;38;2;122;162;247:*.mount=0;38;2;180;249;248:*.automount=0;38;2;180;249;248:*.swap=0;38;2;180;249;248:*.path=0;38;2;180;249;248:*.slice=0;38;2;180;249;248:*.scope=0;38;2;180;249;248:*.nix=0;38;2;42;195;222:*.flake=0;38;2;42;195;222:*.lock=0;38;2;42;195;222:*.gitignore=0;38;2;42;195;222:*.gitattributes=0;38;2;42;195;222:*.gitmodules=0;38;2;42;195;222:*.gitconfig=0;38;2;42;195;222:*.hgrc=0;38;2;42;195;222:*.hgignore=0;38;2;42;195;222:*.svnignore=0;38;2;42;195;222:*.bzrignore=0;38;2;42;195;222:*.cvsignore=0;38;2;42;195;222:*.dockerignore=0;38;2;42;195;222:*.fdignore=0;38;2;42;195;222:*.rgignore=0;38;2;42;195;222:*.ignore=0;38;2;42;195;222:*.editorconfig=0;38;2;42;195;222:'

# EZA {
# A modern replacement for ls
# https://eza.rocks
export EXA_COLORS="di=1;38;2;122;162;247:ex=01;38;5;10:fi=0;38;2;192;202;245:pi=2;38;2;65;72;104:so=3;38;2;65;72;104:bd=4;38;2;224;175;104:cd=0;38;2;224;175;104:ln=04;01;38;5;205:or=0;38;2;157;124;216:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
# }
