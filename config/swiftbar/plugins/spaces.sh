#!/usr/bin/env bash
# The yabai space strip (docs/TILING.md): yb bar prints it; yabairc refreshes it through
# swiftbar://refreshplugin?name=spaces. SwiftBar runs plugins with a bare PATH.
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
exec "$HOME/.local/bin/yb" bar
