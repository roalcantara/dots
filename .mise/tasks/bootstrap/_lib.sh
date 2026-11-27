#!/usr/bin/env bash
# Shared by every bootstrap step: paths, the profile, platform guards, warnings and logging.
# Sourced, never run. It only defines things and sets no shell options: each step chooses its own.

DOTS_DIR="${DOTS_DIR:-$HOME/.local/share/dots}"

# Validate usage_profile (from each step's --profile flag, backed by DOTS_PROFILE, default desktop).
# Exits 2 on any name outside desktop, dev, container.
validate_profile()
                   {
  local list="${usage_profile:-desktop}" item
  local IFS=', '
  for item in $list; do
    [ -n "$item" ] || continue
    case "$item" in
      desktop | dev | container) ;;
      *)
        printf 'bootstrap: unknown profile: %s (expected desktop, dev, or container)\n' "$item" >&2
        exit 2
        ;;
    esac
  done
}

# True when usage_profile contains exactly this name (split on commas or spaces): dev does not match devops.
has_profile()
              {
  validate_profile
  local target="$1" list="${usage_profile:-desktop}" item
  local IFS=', '
  for item in $list; do
    [ "$item" = "$target" ] && return 0
  done
  return 1
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
  validate_profile
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
}
