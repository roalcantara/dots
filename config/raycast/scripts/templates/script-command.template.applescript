#!/usr/bin/osascript

# Raycast Script Command: AppleScript
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.applescript
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title My First Script
# @raycast.mode fullOutput
# @raycast.packageName Raycast Scripts
#
# Optional parameters:
# @raycast.icon ??
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false
# @raycast.argument1 { "type": "password", "placeholder": "Arg1" }
# @raycast.argument2 { "type": "text", "placeholder": "from city", "percentEncoded": true }
# @raycast.argument3 { "type": "text", "placeholder": "to city", "percentEncoded": true, "optional": true }
# @raycast.argument4 { "type": "dropdown", "placeholder": "Position on Screen", "data": [{"title": "Left", "value": "left"}, {"title": "Right", "value": "right"}, {"title": "Bottom", "value": "bottom"}] }
#
# Documentation:
# @raycast.description Write a nice and descriptive summary about your script command here
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara

on run argv
  log "Hello from My First Script: " & ( item 1 of argv )
end run

# vi: set ft=applescript
