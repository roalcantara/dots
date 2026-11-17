# shellcheck shell=sh
# eza and ls colours for this theme: EZA_CONFIG_DIR (eza/theme.yml) and LS_COLORS (ls_colors). Sourced by zsh
# (config/zsh/opt/rc.d/theme.zsh) and bash (config/bash/bashrc) with DOTS_EZA_DIR set to this folder, which is the
# theme's own unless config/dots/config.toml's `eza` names another theme. POSIX, for both shells.

export EZA_CONFIG_DIR="$DOTS_EZA_DIR/eza"
# Dracula's own eza colours (dracula/eza, draculatheme.com/eza): its EZA_COLORS uses the terminal's basic colours
# (34, 95, 36, …), which only look like Dracula in a Dracula terminal. These are the same keys in Dracula's hex
# values (34 purple #bd93f9, 95 bright pink #ff92df, 36 cyan #8be9fd, 35 pink #ff79c6, 31 red, 37 white, 2;34 dim
# purple), plus eza's defaults for sizes and git in the same palette. They override eza/theme.yml key by key.
export EZA_COLORS="ur=38;2;189;147;249:uw=38;2;255;146;223:ux=38;2;139;233;253:ue=38;2;139;233;253:gr=38;2;189;147;249:gw=38;2;255;121;198:gx=38;2;139;233;253:tr=38;2;189;147;249:tw=38;2;255;121;198:tx=38;2;139;233;253:su=38;2;255;121;198:sf=38;2;255;121;198:uu=38;2;139;233;253:uR=38;2;255;85;85:un=38;2;255;121;198:gu=38;2;248;248;242:da=2;38;2;189;147;249:xx=38;2;255;146;223:sn=1;38;2;80;250;123:sb=38;2;80;250;123:ga=38;2;80;250;123:gm=38;2;189;147;249:gd=38;2;255;85;85:gv=38;2;241;250;140:gt=38;2;255;121;198"
[ -r "$DOTS_EZA_DIR/ls_colors" ] && . "$DOTS_EZA_DIR/ls_colors"
