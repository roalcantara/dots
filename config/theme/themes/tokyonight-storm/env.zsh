# Sourced by the shell's theme loader (config/zsh/opt/rc.d/theme.zsh), which first sets
# DOTS_THEME_DIR to this folder; it never runs a process. Tokyo Night Storm (folke/tokyonight.nvim):
# its palette, its fzf colours (extras/fzf), and the pre-theme ls and eza palettes kept as they were.

export BAT_THEME="tokyonight_storm"
export EZA_CONFIG_DIR="$DOTS_THEME_DIR/eza"
# The pre-theme eza palette, kept as it was (it overrides eza/theme.yml key by key).
export EZA_COLORS="di=1;38;2;122;162;247:ex=01;38;5;10:fi=0;38;2;192;202;245:pi=2;38;2;65;72;104:so=3;38;2;65;72;104:bd=4;38;2;224;175;104:cd=0;38;2;224;175;104:ln=04;01;38;5;205:or=0;38;2;157;124;216:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
export MISE_COLOR_THEME=default
export GLOW_STYLE=dark

# fzf colours: folke's tokyonight_storm fzf extra plus the framed-style section backgrounds and labels.
export FZF_THEME_OPTS="--color=bg:#1F2335 --color=fg:#C0CAF5 --color=hl:#2AC3DE --color=bg+:#2E3C64 --color=fg+:#C0CAF5 --color=hl+:#2AC3DE --color=info:#545C7E --color=prompt:#2AC3DE --color=pointer:#FF007C --color=marker:#FF007C --color=spinner:#FF007C --color=header:#FF9E64 --color=selected-bg:#3B4261 --color=border:#29A4BD --color=label:#C0CAF5 --color=list-bg:#1F2335 --color=input-bg:#292E42 --color=preview-bg:#1F2335 --color=list-border:#29A4BD --color=input-border:#29A4BD --color=preview-border:#29A4BD --color=list-label:#C0CAF5 --color=preview-label:#C0CAF5"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#565F89"

# Risky commands: the theme's red background, dark text, bold (see docs/THEME.md).
export DOTS_WARN_STYLE="fg=#1F2335,bg=#F7768E,bold"

# powerlevel10k reads these in .p10k.zsh, which keeps its old values as defaults.
export DOTS_P10K_GREY=242
export DOTS_P10K_RED="#F7768E"
export DOTS_P10K_YELLOW="#E0AF68"
export DOTS_P10K_BLUE="#7AA2F7"
export DOTS_P10K_MAGENTA="#BB9AF7"
export DOTS_P10K_CYAN="#7DCFFF"
export DOTS_P10K_WHITE="#C0CAF5"

# fzf-tab's group colours, in order: magenta, blue, green, orange, cyan, yellow.
typeset -ga DOTS_FZF_TAB_GROUP_COLORS=(
  $'\e[38;2;187;154;247m'
  $'\e[38;2;122;162;247m'
  $'\e[38;2;158;206;106m'
  $'\e[38;2;255;158;100m'
  $'\e[38;2;125;207;255m'
  $'\e[38;2;224;175;104m'
)

source "$DOTS_THEME_DIR/ls_colors"
