# Sourced by bash's startup (config/bash/bashrc), which first sets DOTS_THEME_DIR to this folder.
# The subset bash uses: bat, eza, mise, glow and the theme's LS_COLORS.

export BAT_THEME="Catppuccin Mocha"
export EZA_CONFIG_DIR="$DOTS_THEME_DIR/eza"
export MISE_COLOR_THEME=catppuccin
export GLOW_STYLE=dark

[ -r "$DOTS_THEME_DIR/ls_colors" ] && . "$DOTS_THEME_DIR/ls_colors"
