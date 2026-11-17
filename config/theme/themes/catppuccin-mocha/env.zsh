# Sourced by the shell's theme loader (config/zsh/opt/rc.d/theme.zsh), which first sets
# DOTS_THEME_DIR to this folder; it never runs a process. The values come from the Catppuccin
# Mocha palette (https://catppuccin.com/palette) and catppuccin/fzf.

export BAT_THEME="Catppuccin Mocha"
export MISE_COLOR_THEME=catppuccin
export GLOW_STYLE=dark

# fzf colours: catppuccin/fzf's flags plus the framed-style section backgrounds and labels.
export FZF_THEME_OPTS="--color=bg:#1E1E2E --color=fg:#CDD6F4 --color=hl:#F38BA8 --color=bg+:#313244 --color=fg+:#CDD6F4 --color=hl+:#F38BA8 --color=info:#CBA6F7 --color=prompt:#CBA6F7 --color=pointer:#F5E0DC --color=marker:#B4BEFE --color=spinner:#F5E0DC --color=header:#F38BA8 --color=selected-bg:#45475A --color=border:#6C7086 --color=label:#CDD6F4 --color=list-bg:#1E1E2E --color=input-bg:#313244 --color=preview-bg:#181825 --color=list-border:#6C7086 --color=input-border:#6C7086 --color=preview-border:#6C7086 --color=list-label:#CDD6F4 --color=preview-label:#CDD6F4"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6C7086"

# Risky commands: the theme's red background, crust text, bold (see docs/THEME.md).
export DOTS_WARN_STYLE="fg=#11111B,bg=#F38BA8,bold"

# powerlevel10k reads these in .p10k.zsh, which keeps its old values as defaults.
export DOTS_P10K_GREY=242
export DOTS_P10K_RED="#F38BA8"
export DOTS_P10K_YELLOW="#F9E2AF"
export DOTS_P10K_BLUE="#89B4FA"
export DOTS_P10K_MAGENTA="#F5C2E7"
export DOTS_P10K_CYAN="#89DCEB"
export DOTS_P10K_WHITE="#CDD6F4"

# fzf-tab's group colours, in order: mauve, blue, green, peach, pink, yellow.
typeset -ga DOTS_FZF_TAB_GROUP_COLORS=(
  $'\e[38;2;203;166;247m'
  $'\e[38;2;137;180;250m'
  $'\e[38;2;166;227;161m'
  $'\e[38;2;250;179;135m'
  $'\e[38;2;245;194;231m'
  $'\e[38;2;249;226;175m'
)
