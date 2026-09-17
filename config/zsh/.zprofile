#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# GNUPG TTY {
  # gpg pinentry needs the controlling terminal. Login shells set it here so
  # that non-interactive login shells (`zsh -lc 'git commit -S ...'`) have it;
  # .zshrc covers non-login interactive shells. .zprofile runs first, and
  # .zshrc reuses ${GPG_TTY:-...}, so $(tty) is spawned at most once.
  [[ -t 0 ]] && export GPG_TTY=${GPG_TTY:-"$(tty)"}
# }
