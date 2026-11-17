#!/usr/bin/env zsh
# Lig, the completion popup (docs/THEME.md): sources its cached zsh integration, written by `mise run zsh:lig`.
# Loaded by .zshrc; defines functions only — nothing runs at load time, and no lig process ever starts here.
#DECLARES lig::pre  lig::post

# True when the cached block $1 (pre or post) can be sourced: lig is installed, not disabled, the block exists, and
# the cache came from this lig binary (${commands[lig]:A} resolves the Homebrew link without a process).
lig::_fresh() {
  local cache=${DOTS_LIG_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/dots/lig} from
  [[ -z ${LIG_DISABLE-} && -n ${commands[lig]-} && -r $cache/$1.zsh && -r $cache/bin ]] || return 1
  read -r from < $cache/bin
  [[ $from == ${commands[lig]:A} ]] && return 0
  # Another lig made the cache (brew upgrade): start without the popup rather than source stale code, and say how
  # to fix it, once per shell (LIG_DISABLE also keeps lig::post and child shells out).
  print -u2 -r -- "lig: upgraded; run \`mise run zsh:lig\` (this shell starts without the popup)"
  export LIG_DISABLE=1
  return 1
}

#ABOUT Restart this interactive shell inside Lig's PTY (Lig's own guards skip scripts, `zsh -c` and non-terminals).
#ORDER First in .zshrc, before p10k's instant prompt: the block execs `lig shell`, which starts zsh again.
lig::pre() {
  # `zsh -ic 'cmd'` and `zsh -i file` from a terminal pass Lig's own guards (interactive, a terminal), but the exec
  # would start a fresh shell and drop the command or script: leave them alone.
  [[ -z ${ZSH_EXECUTION_STRING-} && -z ${ZSH_SCRIPT-} ]] || return 0
  lig::_fresh pre && source ${DOTS_LIG_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/dots/lig}/pre.zsh
  return 0
}

#ABOUT Connect zle to Lig's popup: report the line, accept insertions, answer completion queries.
#ORDER Last in .zshrc, after every other zle widget and hook.
lig::post() {
  lig::_fresh post && source ${DOTS_LIG_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/dots/lig}/post.zsh
  return 0
}
