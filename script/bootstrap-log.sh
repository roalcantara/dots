# shellcheck shell=sh
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
# A named pipe, not bash's `exec > >(tee …)`: mise runs hooks with `sh`, which is dash on Linux and bash 3.2 in
# POSIX mode on macOS, and neither has process substitution. tee reads the pipe in the background; the pipe's name
# is removed once both ends are open.
if [ -z "${DOTS_LOG_TEED:-}" ]; then
  dots_log_fifo="$(mktemp -u "${TMPDIR:-/tmp}/dots-log.XXXXXX")"
  if mkfifo -m 600 "$dots_log_fifo" 2> /dev/null; then
    export DOTS_LOG_TEED=1
    tee -a "$DOTS_LOG" < "$dots_log_fifo" &
    exec > "$dots_log_fifo" 2>&1
    rm -f "$dots_log_fifo"
  fi
fi
