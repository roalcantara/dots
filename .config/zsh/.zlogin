#!/usr/bin/env zsh

# ~/.zlogin
# Sourced in login shells - AFTER `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# Contains commands to set the terminal type and run a series of external commands (fortune, msgs, etc)
function extract_completions_and_compile() {
  dots zsh compile --all;
  unset -f extract_completions_and_compile
}

if [ -z "$z_prof" ]; then
  # run in the background to not affect the current session
  extract_completions_and_compile &> /dev/null 2>&1
fi
