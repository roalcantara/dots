#!/usr/bin/env zsh
# Terminal detection, shell integration and prompt.
# Loaded by .zshrc; defines functions only — nothing runs at load time.
#DECLARES term::profile  term::prompt

#ABOUT Detect the terminal, set ZSH_MINIMAL_TERMINAL and load its shell integration.
#ORDER Before ZIM: init.zsh evaluates ZSH_MINIMAL_TERMINAL at runtime.
term::profile() {
  # Single source of truth for terminal detection. Everything downstream
  # (ZIM module conditions, prompt, shell integration) reads from here.
  #
  # ZSH_MINIMAL_TERMINAL marks a terminal that provides its own prompt,
  # syntax highlighting and suggestions, and therefore conflicts with ours.
  # It is NOT a general "IDE" flag: VS Code has none of those and gets the
  # full experience. Set it yourself to force any terminal down.
  export TERM="${TERM:-xterm-256color}"
  typeset -g _zsh_term=${(L)TERM_PROGRAM}

  if [[ -n "$ZSH_MINIMAL_TERMINAL" || "$_zsh_term" == warp(|terminal) ]]; then
    export ZSH_MINIMAL_TERMINAL=1
  else
    unset ZSH_MINIMAL_TERMINAL
  fi

  case "$_zsh_term" in
    ghostty)
      for _zsh_ghostty in \
        "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration" \
        /Applications/Ghostty.app/Contents/Resources/ghostty/shell-integration/zsh/ghostty-integration
      do
        if [[ -r "$_zsh_ghostty" ]]; then source "$_zsh_ghostty"; break; fi
      done
      unset _zsh_ghostty
      export SNACKS_GHOSTTY=true
      ;;
    vscode|vscode-insider)
      # VSCODE_INJECTION=1 means VS Code already sourced its integration
      # (shellIntegration-rc.zsh branches on it), so there is nothing to do.
      if [[ "$VSCODE_INJECTION" != 1 ]] && _has_command code; then
        # `code --locate-shell-integration-path zsh` boots the Electron CLI
        # (~78ms) to return a constant path. Cache it against the app bundle.
        typeset -g _zsh_vsc_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/vscode-shell-integration"
        typeset -g _zsh_vsc_path=''
        [[ -r "$_zsh_vsc_cache" ]] && _zsh_vsc_path="$(<"$_zsh_vsc_cache")"
        if [[ ! -r "$_zsh_vsc_path" ]]; then
          _zsh_vsc_path="$(code --locate-shell-integration-path zsh 2>/dev/null)"
          if [[ -r "$_zsh_vsc_path" ]]; then
            mkdir -p "${_zsh_vsc_cache:h}"
            print -r -- "$_zsh_vsc_path" > "$_zsh_vsc_cache"
          fi
        fi
        [[ -r "$_zsh_vsc_path" ]] && source "$_zsh_vsc_path"
        unset _zsh_vsc_cache _zsh_vsc_path
      fi
      ;;
    kiro)
      _has_command kiro && source "$(kiro --locate-shell-integration-path zsh)"
      ;;
  esac
  unset _zsh_term
}

#ABOUT Load the powerlevel10k configuration.
#ORDER After ZIM, which sources the theme.
term::prompt() {
  [[ ! -f ${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh ]] || source ${ZDOTDIR:-$HOME/.config/zsh}/.p10k.zsh
}
