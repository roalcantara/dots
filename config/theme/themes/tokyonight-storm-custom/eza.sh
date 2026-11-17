# shellcheck shell=sh
# eza and ls colours for this theme: EZA_CONFIG_DIR (eza/theme.yml) and LS_COLORS (ls_colors). Sourced by zsh
# (config/zsh/opt/rc.d/theme.zsh) and bash (config/bash/bashrc) with DOTS_EZA_DIR set to this folder, which is the
# theme's own unless config/dots/config.toml's `eza` names another theme. POSIX, for both shells.

export EZA_CONFIG_DIR="$DOTS_EZA_DIR/eza"
# The pre-theme eza palette, kept as it was (it overrides eza/theme.yml key by key).
export EZA_COLORS="di=1;38;2;122;162;247:ex=01;38;5;10:fi=0;38;2;192;202;245:pi=2;38;2;65;72;104:so=3;38;2;65;72;104:bd=4;38;2;224;175;104:cd=0;38;2;224;175;104:ln=04;01;38;5;205:or=0;38;2;157;124;216:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
[ -r "$DOTS_EZA_DIR/ls_colors" ] && . "$DOTS_EZA_DIR/ls_colors"
