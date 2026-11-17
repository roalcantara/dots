# Sourced by the shell's theme loader (config/zsh/opt/rc.d/theme.zsh), which first sets
# DOTS_THEME_DIR to this folder; it never runs a process. The values come from the Catppuccin
# Macchiato palette (https://catppuccin.com/palette) and catppuccin/fzf.

export BAT_THEME="Catppuccin Macchiato"
export EZA_CONFIG_DIR="$DOTS_THEME_DIR/eza"
export MISE_COLOR_THEME=catppuccin
export GLOW_STYLE=dark

# fzf colours: catppuccin/fzf's flags plus the framed-style section backgrounds and labels.
export FZF_THEME_OPTS="--color=bg:#24273A --color=fg:#CAD3F5 --color=hl:#ED8796 --color=bg+:#363A4F --color=fg+:#CAD3F5 --color=hl+:#ED8796 --color=info:#C6A0F6 --color=prompt:#C6A0F6 --color=pointer:#F4DBD6 --color=marker:#B7BDF8 --color=spinner:#F4DBD6 --color=header:#ED8796 --color=selected-bg:#494D64 --color=border:#6E738D --color=label:#CAD3F5 --color=list-bg:#24273A --color=input-bg:#363A4F --color=preview-bg:#1E2030 --color=list-border:#6E738D --color=input-border:#6E738D --color=preview-border:#6E738D --color=list-label:#CAD3F5 --color=preview-label:#CAD3F5"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6E738D"

# Risky commands: the theme's red background, crust text, bold (see docs/THEME.md).
export DOTS_WARN_STYLE="fg=#181926,bg=#ED8796,bold"

# powerlevel10k reads these in .p10k.zsh, which keeps its old values as defaults.
export DOTS_P10K_GREY=242
export DOTS_P10K_RED="#ED8796"
export DOTS_P10K_YELLOW="#EED49F"
export DOTS_P10K_BLUE="#8AADF4"
export DOTS_P10K_MAGENTA="#F5BDE6"
export DOTS_P10K_CYAN="#91D7E3"
export DOTS_P10K_WHITE="#CAD3F5"

# fzf-tab's group colours, in order: mauve, blue, green, peach, pink, yellow.
typeset -ga DOTS_FZF_TAB_GROUP_COLORS=(
  $'\e[38;2;198;160;246m'
  $'\e[38;2;138;173;244m'
  $'\e[38;2;166;218;149m'
  $'\e[38;2;245;169;127m'
  $'\e[38;2;245;189;230m'
  $'\e[38;2;238;212;159m'
)

source "$DOTS_THEME_DIR/ls_colors"
