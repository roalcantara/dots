#!/usr/bin/env python3

# Raycast Script Command: Python (requires Python3)
# https://github.com/raycast/script-commands
# SOURCE: https://github.com/raycast/script-commands/blob/master/templates/script-command.template.php
# ARGUMENTS: https://github.com/raycast/script-commands/blob/master/documentation/ARGUMENTS.md
# OUTPUTMODES: https://github.com/raycast/script-commands/blob/master/documentation/OUTPUTMODES.md
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title String Command Example
# @raycast.mode fullOutput
# @raycast.packageName Raycast Scripts
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.currentDirectoryPath ~
# @raycast.needsConfirmation false
# @raycast.argument1 {"type": "text", "placeholder": "path/to/file.xml"}
# @raycast.argument2 {"type": "dropdown", "placeholder": "path/to/file.xml", "data": [{"title": "Label1", "value": "value1"}, {"title": "Label2", "value": "value2"}]}
# @raycast.argument3 {"type": "text", "placeholder": "Optional", "optional": true}
# @raycast.argument4 {"type": "password", "placeholder": "Password"}
#
# Documentation:
# @raycast.description Python script command example
# @raycast.author roalcantara
# @raycast.authorURL https://github.com/roalcantara
#
# USAGE:
# python script-command.template.py 'hi' 'there' '/path/to/file.xml' 'password'

import sys
args = sys.argv[1:]  # capture all arguments passed to the script

print("Hello World! " + " ".join(args))

# vi: set ft=python
