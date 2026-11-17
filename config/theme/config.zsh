#!/usr/bin/env zsh
# Reads the theme choice from the dots config file (config/dots/config.toml, linked to ~/.config/dots/config.toml).
# Sourced by config/zsh/opt/rc.d/theme.zsh, config/bin/dots and the bootstrap hook; bash has its own copy of the
# same loop in config/bash/bashrc. Builtins only: a shell start must not run a process to read it.
#DECLARES theme::config  theme::config_file

# The file: DOTS_CONFIG overrides it (tests).
theme::config_file() {
  print -r -- "${DOTS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/dots/config.toml}"
}

# reply=(name eza): the [theme] table's `name` and `eza`, empty when absent. A deliberately small TOML reader:
# `[table]` headers and `key = "value"` lines, with comments allowed after the value; anything else is ignored.
theme::config() {
  emulate -L zsh
  local file=${1:-$(theme::config_file)} line section= name= eza=
  reply=("" "")
  [[ -r $file ]] || return 1
  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $line =~ '^[[:space:]]*\[([^]]+)\][[:space:]]*(#.*)?$' ]]; then
      section=${match[1]//[[:space:]]/}
    elif [[ $section == theme && $line =~ '^[[:space:]]*(name|eza)[[:space:]]*=[[:space:]]*"([^"]*)"' ]]; then
      if [[ ${match[1]} == name ]]; then name=${match[2]}; else eza=${match[2]}; fi
    fi
  done < $file
  reply=("$name" "$eza")
}
