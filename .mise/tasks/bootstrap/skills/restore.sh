#!/usr/bin/env bash
#MISE description="Restore the agent skills from the lockfile in the background (dev only)"
# Agent skills from config/agents/skill-lock.json, in the background: hundreds of skills must not hold up the
# bootstrap. A notification and ~/.local/state/dots/skills-restore.result report the outcome. dev only.
. "${BASH_SOURCE%/*}/../_lib.sh"
set -euo pipefail
has_profile dev || exit 0
bootstrap_init

skills_state="${XDG_STATE_HOME:-$HOME/.local/state}/dots"
mkdir -p "$skills_state"
if [ -n "${DOTS_SKILLS_FOREGROUND:-}" ]; then
  mise run -C "$DOTS_DIR" skills:restore || warn "skills:restore"
else
  nohup mise run -C "$DOTS_DIR" skills:restore -- --background > "$skills_state/skills-restore.log" 2>&1 < /dev/null &
  echo "bootstrap: restoring agent skills in the background (log: $skills_state/skills-restore.log)"
fi
