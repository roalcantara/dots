#!/usr/bin/env bash
# Shared by every bootstrap step: paths, the profile, platform guards, warnings and logging.
# Sourced, never run. It only defines things and sets no shell options: each step chooses its own.

DOTS_DIR="${DOTS_DIR:-$HOME/.local/share/dots}"

# The comma list of profiles this run applies to. The first non-empty source wins: DOTS_PROFILE, MISE_ENV, the
# parent's -E/--env (mise bootstrap -E desktop,dev), miserc.local.toml's env, then desktop.
dots_profile()
               {
  local profile="${DOTS_PROFILE:-}" args=""
  [ -n "$profile" ] || profile="${MISE_ENV:-}"
  if [ -z "$profile" ]; then
    if [ -r "/proc/$PPID/cmdline" ]; then
      profile="$(tr '\0' '\n' < "/proc/$PPID/cmdline" | sed -n 's/^--env=//p')"
      [ -n "$profile" ] || profile="$(tr '\0' '\n' < "/proc/$PPID/cmdline" | grep -A1 -E '^(-E|--env)$' | tail -1 || true)"
    elif command -v ps > /dev/null; then
      args="$(ps -o args= -p "$PPID" 2> /dev/null || true)"
      profile="$(printf '%s\n' "$args" | grep -oE -- '(-E|--env)[ =][a-zA-Z0-9_,-]+' | head -1 | awk '{print $NF}' | tr -d '=' || true)"
    fi
  fi
  if [ -z "$profile" ] && [ -f "$DOTS_DIR/config/mise/miserc.local.toml" ]; then
    profile="$(sed -n 's/^env *= *\[\(.*\)\].*/\1/p' "$DOTS_DIR/config/mise/miserc.local.toml" | tr -d '" ')"
  fi
  printf '%s\n' "${profile:-desktop}"
}

# True when the profile list contains exactly this name: dev does not match devops.
has_profile()
              {
  case ",$(dots_profile)," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

is_macos()
           {
  [ "${DOTS_UNAME:-$(uname -s)}" = Darwin ]
}

# Soft failure: say what failed and carry on. Under DOTS_STRICT or CI, fail the phase instead, as today.
warn()
       {
  if [ -n "${DOTS_STRICT:-}${CI:-}" ]; then
    printf 'bootstrap: %s failed\n' "$1" >&2
    exit 1
  fi
  printf 'bootstrap: %s failed, continuing\n' "$1" >&2
}

# Make this phase's tools reachable before it runs a task: ~/.local/bin is not linked yet in early phases,
# Homebrew's prefix is where the packages land, and the log captures every step.
bootstrap_init()
                 {
  export PATH="$HOME/.local/bin:$PATH"
  local b brew=""
  for b in "$(command -v brew || true)" /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    [ -n "$b" ] && [ -x "$b" ] && {
      brew="$b"
      break
    }
  done
  if [ -n "$brew" ]; then
    eval "$("$brew" shellenv)"
  fi
  if [ -r "$DOTS_DIR/script/bootstrap-log.sh" ]; then
    . "$DOTS_DIR/script/bootstrap-log.sh"
  fi
  export DOTS_PROFILE="$(dots_profile)"
}
