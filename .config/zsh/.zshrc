# shellcheck shell=bash disable=SC1090

# ~/.zshrc
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://zsh.sourceforge.io/Contrib/startup/std/zshrc
# Contains commands that loads shell options, aliases, functions, key bindings and plugins

# profilling:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# tracing
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
#   z_prof=1 z_trace=1 z_bug=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof;
if [[ -n "$z_trace" || -n "$z_xtrace" ]]; then
  if [ -n "$z_xtrace" ]; then
    zmodload zsh/datetime
    setopt PROMPT_SUBST
    PS4='$EPOCHREALTIME#%N:%i => '
  fi
  setopt XTRACE
fi

bindkey -v
source ~/.config/zsh/opt/include/autoload.zsh;
source ~/.config/.login;
source ~/.config/zsh/opt/include/compile.zsh;

[ -n "$z_prof" ] && zprof;
if [[ -n "$z_trace" || -n "$z_xtrace" ]]; then
  unsetopt XTRACE
fi
