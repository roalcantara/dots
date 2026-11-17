#!/usr/bin/env zsh
# Shell theme: resolves the active theme folder (dots theme) and sources its env.zsh once.
# Loaded by .zshrc; nothing runs at load time, and a missing theme leaves tools on their built-in colours.
#DECLARES theme::palette

#ABOUT Resolve the active shell theme and export its values (BAT_THEME, FZF_THEME_OPTS, LS_COLORS, …).
#ORDER Before ZIM: powerlevel10k reads the DOTS_P10K_* colours at load.
theme::palette() {
  export DIRSTACKSIZE=${DIRSTACKSIZE:-100}
  export PAGER=${PAGER:-"less -FREXi"}
  export BROWSER=${BROWSER:-"open"}
  export MANROFFOPT=${MANROFFOPT:-"-c"}
  export CLICOLOR=${CLICOLOR:-1}

  local themes_dir="${DOTS_THEMES_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/theme/themes}"
  local theme_link="${DOTS_THEME_LINK:-${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current}"
  local theme_dir=""

  # The current link is the source of truth; when it is missing or dangling, Mocha is the default.
  [[ -d "$theme_link" ]] && theme_dir="${theme_link:A}"
  [[ -n "$theme_dir" ]] || theme_dir="$themes_dir/catppuccin-mocha"

  # No theme folder at all (a bare container, say): export nothing and keep each tool's own colours.
  if [[ -r "$theme_dir/env.zsh" ]]; then
    export DOTS_THEME_DIR="$theme_dir"
    source "$theme_dir/env.zsh"
  fi
}

theme::palette
