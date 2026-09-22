#!/usr/bin/env zsh
# ZIM lifecycle: what it needs beforehand, and what must outrank it afterwards.
# Loaded by .zshrc; defines functions only — nothing runs at load time.
#DECLARES zim::dumpfile  zim::load  zim::overrides

#ABOUT Tell ZIM where to write the completion dump.
#ORDER Before ZIM sources init.zsh.
zim::dumpfile() {
  # Read at runtime by ZIM's completion module, so it must be set here and
  # not in .zimrc (which only executes when ZIM rebuilds init.zsh).
  zstyle ':zim:completion' dumpfile "${zdumpfile:-${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache/.zcompdump}"
}

#ABOUT Re-assert settings that ZIM's modules would otherwise win.
#ORDER After ZIM. Must NOT use `emulate -L zsh`: it sets options globally.
zim::overrides() {
  # ZIM's modules set options and completion styles as they load. Anything
  # we want to outrank them must run here, after init.zsh. Keep this block
  # as the single place where ZIM defaults are overridden.

  # mise re-runs `mise hook-env` on EVERY prompt (measured 8.3ms steady-state).
  # Its chpwd hook already covers directory changes, which is what actually
  # invalidates the environment in practice, so drop the precmd hook and keep
  # chpwd. This preserves the env vars mise exports (GOROOT, GOBIN, per-project
  # [env] such as LUA_PATH) that `mise activate --shims` would NOT set.
  # Trade-off: editing a mise config without changing directory needs a manual
  # refresh -> use `mise-refresh`.
  if (( ${+functions[_mise_hook_precmd]} )); then
    autoload -Uz add-zsh-hook
    add-zsh-hook -d precmd _mise_hook_precmd
    mise-refresh() { _mise_hook --force }
  fi

  # ZIM's environment module sets NO_CLOBBER. It breaks `>` over an existing
  # file for every script and tool that assumes zsh's default, including
  # Claude Code. Scripts wanting protection opt in with `set -o noclobber`.
  setopt CLOBBER

  # Set once here; .zshenv previously set the same option three times.
  setopt no_mail_warning

  # Completion styles ZIM's completion module would otherwise win.
  zstyle ':completion:*' menu select=2
  zstyle ':completion:*' squeeze-slashes no
  zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

  # zim-starship sets this to 1; we want the right prompt flush to the edge.
  export ZLE_RPROMPT_INDENT=0

  # Terminals that draw their own prompt get a plain one. PROMPT is
  # deliberately NOT exported: zim-starship assigns a command substitution
  # into it, which would then leak into every child process.
  if [[ -n "$ZSH_MINIMAL_TERMINAL" ]]; then
    setopt prompt_subst
    PROMPT='❯ '
    RPROMPT=''
    PS1="$PROMPT"
  fi
}

#ABOUT Bootstrap zimfw and source the generated init.zsh.
#ORDER After zim::dumpfile, before zim::overrides.
zim::load() {
  local zdot=${ZDOTDIR:-$HOME/.config/zsh}
  [[ -e $zdot/.zimrc ]] || return 0

  # This function runs after .zshrc's instant-prompt preamble, so anything it
  # writes to the console makes p10k warn about "console output during zsh
  # initialization" on the next start. Neither step below is silent when it
  # actually runs: wget reports download failures, and `zimfw init` prints
  # clone/build progress whenever .zimrc gained a module. Both are rare, both
  # are uninteresting when they succeed -- so their output goes to a log, and
  # only a real failure is allowed to reach the terminal.
  local zlog=$zdot/tmp/zim-bootstrap.log

  if [[ ! -e $ZIM_HOME/zimfw.zsh ]]; then
    command mkdir -p $ZIM_HOME ${zlog:h}
    # >| overrides NO_CLOBBER: zim::overrides has not run yet to turn it off.
    if ! command wget -q -O $ZIM_HOME/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh >|$zlog 2>&1; then
      print -u2 "zim::load: could not download zimfw.zsh - see $zlog"
      return 1
    fi
  fi
  if [[ ! $ZIM_HOME/init.zsh -nt $zdot/.zimrc ]]; then
    command mkdir -p ${zlog:h}
    if ! source $ZIM_HOME/zimfw.zsh init -q >|$zlog 2>&1; then
      print -u2 "zim::load: zimfw init failed - see $zlog"
      return 1
    fi
  fi
  [[ -f $ZIM_HOME/init.zsh ]] && source $ZIM_HOME/init.zsh
  return 0
}
