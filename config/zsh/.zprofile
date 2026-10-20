#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# Android SDK Tools
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
for d in "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/cmdline-tools/latest/bin" "$ANDROID_HOME/emulator"; do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) export PATH="$d:$PATH" ;;
  esac
done
