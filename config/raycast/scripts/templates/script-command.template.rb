#!/usr/bin/env ruby

# Raycast Script Command: Ruby
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.php
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
# @raycast.icon 🤖
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false
# @raycast.argument1 { "type": "text", "placeholder": "Placeholder text" }
#
# Documentation:
# @raycast.description Write a nice and descriptive summary about your script command here
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara

def say(message)
  puts message
end

say(ARGV[0]) if ARGV[0]

# vi: set ft=ruby
