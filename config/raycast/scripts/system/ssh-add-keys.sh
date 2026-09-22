#!/usr/bin/env zsh

# Raycast Script Command: Shell
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.sh
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Add SSH Keys
# @raycast.mode inline

# Optional parameters:
# @raycast.icon ../images/ssh.svg
# @raycast.packageName System

# Documentation:
# @raycast.description Add SSH Keys to the Apple keychain and list them
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara

if [ -f ~/.ssh/keys/id_ed25519_github.key ]; then
  ssh-add --apple-use-keychain ~/.ssh/keys/id_ed25519_github.key && ssh-add -l
fi