#!/usr/bin/env zsh

# Raycast Script Command: Shell
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.sh
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Bump BREW Dependencies
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon ../images/brew.svg
# @raycast.packageName System
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false

# Documentation:
# @raycast.description Bump BREW Dependencies
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara

CMDS=(
  "brew bundle upgrade --upgrade --zap --force --force-cleanup --verbose"
  "brew autoremove && brew update --auto-update --force --verbose"
  "brew upgrade --greedy --greedy-latest --greedy-auto-updates --yes --force"
  "brew upgrade --greedy --greedy-latest --greedy-auto-updates --force --yes --cask"
  "brew cleanup --prune=all && brew doctor"
)

for CMD in "${CMDS[@]}"; do
  echo "" && echo "$CMD"
  eval "$CMD 2> /dev/null || true"
done