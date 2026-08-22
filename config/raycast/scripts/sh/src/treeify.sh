#!/bin/bash

# Raycast Script Command: Shell
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.sh
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Convert text into a valid tree output
# @raycast.mode fullOutput
# @raycast.packageName Developer Tools
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false
# @raycast.argument1 { "type": "text", "placeholder": "text", "optional": true, "percentEncoded": false }
#
# Documentation:
# @raycast.description Convert text into a valid tree
# @raycast.author roalcantara
# @raycast.authorURL https://raycast.com/roalcantara

if [ -z "$1" ]; then
    INPUT=$(pbpaste)
else
    INPUT=$1
fi

if [ -z "$INPUT" ]; then
  echo "No text provided. Please provide text to convert into a tree."
  exit 1
fi

if [ ! -x "$HOME/.local/bin/xc" ]; then
  echo "xc command not found. Please install it first."
  exit 1
fi

if ! RES=$("$HOME/.local/bin/xc" treeify "$INPUT"); then
  echo "Error: $RES"
  exit 1
fi

echo "$RES"
