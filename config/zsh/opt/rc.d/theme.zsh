#!/usr/bin/env zsh
# Shell theme: reads the theme from the dots config file (config/dots/config.toml), sources the theme's env.zsh and
# the eza theme's eza.sh, and points the theme link (Ghostty, Lig) at the theme when the file changed.
# Loaded by .zshrc; no process runs unless the theme changed, and a missing theme leaves tools on their own colours.
#DECLARES theme::palette

#ABOUT Resolve the shell theme and export its values (BAT_THEME, FZF_THEME_OPTS, LS_COLORS, …).
#ORDER Before ZIM: powerlevel10k reads the DOTS_P10K_* colours at load.
theme::palette() {
  export DIRSTACKSIZE=${DIRSTACKSIZE:-100}
  export PAGER=${PAGER:-"less -FREXi"}
  export BROWSER=${BROWSER:-"open"}
  export MANROFFOPT=${MANROFFOPT:-"-c"}
  export CLICOLOR=${CLICOLOR:-1}

  # eza prefers EZA_COLORS (and the legacy EXA_COLORS) to the theme's eza/theme.yml, and the pre-theme palette
  # exported these: apps started before the switch still pass them on. The theme owns these colours.
  unset EZA_COLORS EXA_COLORS LSCOLORS

  local themes_dir="${DOTS_THEMES_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/theme/themes}"
  local theme_link="${DOTS_THEME_LINK:-${XDG_STATE_HOME:-$HOME/.local/state}/dots/theme/current}"
  local theme_dir="" eza_dir="" name eza
  local -a reply unknown

  # The config file is the source of truth; without one, the link a previous shell left.
  [[ -r "${themes_dir:h}/config.zsh" ]] && source "${themes_dir:h}/config.zsh"
  if (( $+functions[theme::config] )) && theme::config; then
    name=$reply[1] eza=$reply[2]
    if [[ -n $name && -r "$themes_dir/$name/env.zsh" ]]; then theme_dir="$themes_dir/$name"; elif [[ -n $name ]]; then unknown+=($name); fi
    if [[ -n $eza && -r "$themes_dir/$eza/eza.sh" ]]; then eza_dir="$themes_dir/$eza"; elif [[ -n $eza ]]; then unknown+=($eza); fi
  elif [[ -r "$theme_link/env.zsh" ]]; then
    theme_dir="${theme_link:A}"
  fi

  if (( $#unknown )); then
    typeset -g _theme_warning="dots: unknown theme ${(j:, :)${(qqq)unknown}} in $(theme::config_file) (see config/theme/themes)"
    # Printed at the first prompt, so p10k's instant prompt does not flag console output during startup.
    if [[ -n ${ZSH_EXECUTION_STRING-} ]]; then
      print -u2 -r -- $_theme_warning
    else
      theme::_warn() { print -u2 -r -- $_theme_warning; precmd_functions=(${precmd_functions:#theme::_warn}); unset _theme_warning; }
      precmd_functions+=(theme::_warn)
    fi
  fi

  # No theme folder at all (a bare container, say): export nothing and keep each tool's own colours.
  [[ -n $theme_dir ]] || return 0
  export DOTS_THEME_DIR="$theme_dir" DOTS_EZA_DIR="${eza_dir:-$theme_dir}"
  source "$theme_dir/env.zsh"
  [[ -r "$DOTS_EZA_DIR/eza.sh" ]] && source "$DOTS_EZA_DIR/eza.sh"

  # Ghostty and Lig read the theme through the link: point it at the file's theme when it changed (never replacing
  # a real folder), with zsh's own ln, then restart zsh-patina, whose daemon caches its theme.
  if [[ ${theme_link:A} != ${theme_dir:A} && ( -L $theme_link || ! -e $theme_link ) ]]; then
    zmodload -F zsh/files b:zf_ln b:zf_mkdir 2>/dev/null
    zf_mkdir -p ${theme_link:h} 2>/dev/null
    zf_ln -sfn $theme_dir $theme_link 2>/dev/null
    local patina=${DOTS_ZSH_PATINA:-zsh-patina}
    (( $+commands[$patina] )) && $patina restart &>/dev/null
  fi
  return 0
}

theme::palette
