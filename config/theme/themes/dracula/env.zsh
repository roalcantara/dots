# Sourced by the shell's theme loader (config/zsh/opt/rc.d/theme.zsh), which first sets
# DOTS_THEME_DIR to this folder; it never runs a process. The values come from the Dracula palette
# (https://draculatheme.com/spec) and dracula/fzf, the colours this shell used before themes.

export BAT_THEME="Dracula"
export MISE_COLOR_THEME=dracula
export GLOW_STYLE=dracula

# fzf colours: dracula/fzf's flags plus the framed-style section backgrounds and labels.
export FZF_THEME_OPTS="--color=bg:#282A36 --color=fg:#F8F8F2 --color=hl:#BD93F9 --color=bg+:#44475A --color=fg+:#F8F8F2 --color=hl+:#BD93F9 --color=info:#FFB86C --color=prompt:#50FA7B --color=pointer:#FF79C6 --color=marker:#FF79C6 --color=spinner:#FFB86C --color=header:#6272A4 --color=selected-bg:#44475A --color=border:#6272A4 --color=label:#F8F8F2 --color=list-bg:#282A36 --color=input-bg:#44475A --color=preview-bg:#21222C --color=list-border:#6272A4 --color=input-border:#6272A4 --color=preview-border:#6272A4 --color=list-label:#F8F8F2 --color=preview-label:#F8F8F2"

export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6272A4"

# Risky commands: the theme's red background, dark text, bold (see docs/THEME.md).
export DOTS_WARN_STYLE="fg=#21222C,bg=#FF5555,bold"

# powerlevel10k reads these in .p10k.zsh, which keeps its old values as defaults.
export DOTS_P10K_GREY=242
export DOTS_P10K_RED="#FF5555"
export DOTS_P10K_YELLOW="#F1FA8C"
export DOTS_P10K_BLUE="#BD93F9"
export DOTS_P10K_MAGENTA="#FF79C6"
export DOTS_P10K_CYAN="#8BE9FD"
export DOTS_P10K_WHITE="#F8F8F2"

# fzf-tab's group colours, in order: purple, cyan, green, orange, pink, yellow (the pre-theme set).
typeset -ga DOTS_FZF_TAB_GROUP_COLORS=(
  $'\e[38;2;189;147;249m'
  $'\e[38;2;139;233;253m'
  $'\e[38;2;80;250;123m'
  $'\e[38;2;255;184;108m'
  $'\e[38;2;255;121;198m'
  $'\e[38;2;241;250;140m'
)
