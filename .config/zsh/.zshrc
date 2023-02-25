# shellcheck shell=bash disable=SC1090

# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc
# Contains commands that loads shell options, aliases, functions, key bindings and plugins

# Use viins keymap as the default.
bindkey -v

# ZSH profilling and tracing
[ -n "$z_prof" ] && zmodload zsh/zprof;
if [[ -n "$z_trace" || -n "$z_xtrace" ]]; then
  if [ -n "$z_xtrace" ]; then
    zmodload zsh/datetime
    setopt PROMPT_SUBST
    PS4='$EPOCHREALTIME#%N:%i => '
  fi
  setopt XTRACE
fi

for f in ${XDG_CONFIG_HOME:-$HOME/.config}/{.login,zsh/etc/**/*.zsh(N)}; do
    source $f;
done

[ -n "$z_prof" ] && zprof;
if [[ -n "$z_trace" || -n "$z_xtrace" ]]; then
  unsetopt XTRACE
fi
