#!/usr/bin/env bash
# Shared by every bootstrap step: paths, the profile, platform guards, warnings and logging.
# Sourced, never run. It only defines things and sets no shell options: each step chooses its own.

DOTS_DIR="${DOTS_DIR:-$HOME/.local/share/dots}"

# The comma list of profiles this run applies to. The first non-empty source wins: DOTS_PROFILE (the bootstrap
# hand-over sets it from mise's `mise_env`, so `mise bootstrap -E desktop,dev` arrives here), MISE_ENV (a step run by
# hand with `mise -E dev run …`), miserc.local.toml's env, then desktop.
dots_profile()
               {
  local profile="${DOTS_PROFILE:-}"
  [ -n "$profile" ] || profile="${MISE_ENV:-}"
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
