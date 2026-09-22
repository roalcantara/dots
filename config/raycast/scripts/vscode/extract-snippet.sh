#!/usr/bin/env bash

# Raycast Script Command: Shell
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.sh
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Extract VSCode Snippet
# @raycast.mode fullOutput
# @raycast.packageName Raycast Scripts
#
# Optional parameters:
# @raycast.icon ../images/vscode.svg
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false
#
# Documentation:
# @raycast.description Convert the contents from the clipboard into a VSCode snippet format
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara

echo pbpaste | jq -R -s '{ "Snippet": { "prefix": "prefix", "body": split("\n"), "description": "Snippet" } }'

# vi: set ft=sh
