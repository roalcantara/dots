#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

term_prog=${(L)TERM_PROGRAM}
if [[ -n "$ZSH_MINIMAL_TERMINAL" || "$term_prog" == "warp" || "$term_prog" == "warpterminal" || "$term_prog" == "vscode" || "$term_prog" == "vscode-insider" || -n "$VSCODE_INJECTION" || -n "$VSCODE_IPC_HOOK_CLI" || -n "$VSCODE_GIT_IPC_HANDLE" ]]; then
  export ZSH_MINIMAL_TERMINAL=1
  if [[ "$term_prog" == "vscode" || "$term_prog" == "vscode-insider" ]]; then
    # IDEs work better with shims than they do environment variable modifications. The simplest way is to add the mise shim directory to PATH.
    # https://mise.jdx.dev/ide-integration.html#adding-shims-to-path-default-shell
    eval "$(mise activate zsh --shims)"
  fi
else
  unset ZSH_MINIMAL_TERMINAL
fi

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


