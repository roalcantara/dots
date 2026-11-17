# shellcheck shell=sh
# eza and ls colours for this theme: EZA_CONFIG_DIR (eza/theme.yml) and LS_COLORS (ls_colors). Sourced by zsh
# (config/zsh/opt/rc.d/theme.zsh) and bash (config/bash/bashrc) with DOTS_EZA_DIR set to this folder, which is the
# theme's own unless config/dots/config.toml's `eza` names another theme. POSIX, for both shells.

export EZA_CONFIG_DIR="$DOTS_EZA_DIR/eza"
[ -r "$DOTS_EZA_DIR/ls_colors" ] && . "$DOTS_EZA_DIR/ls_colors"
