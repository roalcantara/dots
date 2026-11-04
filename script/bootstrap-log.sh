# shellcheck shell=bash
# Sourced by the post-packages hook and the bootstrap task: copy this script's output into the run's log in
# ~/.local/state/dots/logs. install sets DOTS_LOG for its whole run and already tees it (DOTS_LOG_TEED=1), so
# this adds no second tee then; a direct `mise bootstrap` reuses a log written in the last 30 minutes (the
# hook's, for the task), else starts a new one. Keeps the 10 newest.
dots_log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/dots/logs"
mkdir -p "$dots_log_dir"
if [ -z "${DOTS_LOG:-}" ]; then
  if [ -n "$(find -L "$dots_log_dir/latest.log" -mmin -30 2> /dev/null)" ]; then
    DOTS_LOG="$dots_log_dir/$(readlink "$dots_log_dir/latest.log")"
  else
    DOTS_LOG="$dots_log_dir/bootstrap-$(date +%Y%m%d-%H%M%S).log"
    : > "$DOTS_LOG"
    ln -sfn "$(basename "$DOTS_LOG")" "$dots_log_dir/latest.log"
  fi
fi
# shellcheck disable=SC2012 # names are ours, no spaces
ls -1t "$dots_log_dir"/bootstrap-*.log 2> /dev/null | tail -n +11 | while IFS= read -r old; do rm -f -- "$old"; done
export DOTS_LOG
if [ -n "${BASH_VERSION:-}" ] && [ -z "${DOTS_LOG_TEED:-}" ]; then
  export DOTS_LOG_TEED=1
  eval 'exec > >(tee -a "$DOTS_LOG") 2>&1'
fi
