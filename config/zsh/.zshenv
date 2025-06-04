#!/usr/bin/env zsh

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# http://zsh.sourceforge.net/Intro/intro_3.html
# https://github.com/jimeh/dotfiles/blob/main/zshenv

# profilling:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# tracing
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof
if [[ -n "$z_trace" ]]; then
  # Set a timestamp and script location in PS4 for better trace readability
  PS4=$'%D{%H:%M:%S} ${(%):-%N:%i}> ' # Adds timestamp, filename, and line number
  # Set logging output to a dedicated log file with a unique session ID
  exec 3>&2 2>>$HOME/.config/zsh/tmp/benchmark.$$.start.log
  setopt xtrace prompt_subst
fi

# Ensure compinit is NOT loaded before Zinit loads in ~/zshrc.
skip_global_compinit=1
NO_GLOBAL_RCS=1

# ==============================================================================
# PATH Setup
# ==============================================================================

# Ensure values in path variable are unique
typeset -U path

# Prevent loading ZSH startup from files /etc on macOS. The /etc/zprofile file
# screws around with PATH, so we want to avoid it, and instead manually load the
# files we care about.
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Setup default PATH just like /etc/zprofile does
  if [ -x "/usr/libexec/path_helper" ]; then
    eval $(/usr/libexec/path_helper -s)
  fi

  # # Load /etc/zshenv if it exists
  # if [ -f "/etc/zshenv" ]; then
  #   source "/etc/zshenv"
  # fi
fi

## INTERNATIONALISATION VARIABLES
# The values that the environment variables may be assigned are not restricted;
# Except that they are considered to end with a null byte and the total space used to store the environment and the arguments to the process is limited to {ARG_MAX} bytes.
# It is unwise to conflict with certain variables that are frequently exported by widely used command interpreters and applications.
# https://pubs.opengroup.org/onlinepubs/7908799/xbd/envvar.html

# LANG, LC_ALL, LC_CTYPE & LC_COLLATE
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_COLLATE=C
# }

# Load system utilities helper
xdg() {
  case "$1" in
  set)
    local var_name="$2"
    local default_value="$3"
    local create_dir="${4:-true}"

    [[ -z "$var_name" ]] && { echo "xdg: xdg set requires variable name" >&2; return 1; }
    [[ -z "$default_value" ]] && { echo "xdg: xdg set requires default value" >&2; return 1; }

    if [[ -z "${(P)var_name}" ]]; then
      export "$var_name"="$default_value"
    fi

    # Create directory if requested and it doesn't exist
    if [[ "$create_dir" == "true" && ! -d "${(P)var_name}" ]]; then
      if ! mkdir -p "${(P)var_name}"; then
        echo "xdg: Failed to create directory '${(P)var_name}' for $var_name" >&2
        return 1
      fi
    fi
    ;;
  ensure-runtime)
    # Validate XDG_RUNTIME_DIR
    if [[ -z "$XDG_RUNTIME_DIR" || "$XDG_RUNTIME_DIR" =~ ^[[:space:]]*$ ]]; then
      export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
    fi

    # Create directory if needed
    if [[ ! -d "$XDG_RUNTIME_DIR" ]]; then
      if ! mkdir -p "$XDG_RUNTIME_DIR"; then
        echo "xdg: Failed to create directory '$XDG_RUNTIME_DIR'" >&2
        return 1
      fi
    fi

    # Helper function to get file stats
    _get_file_stats() {
      local dir="$1"
      if command -v stat >/dev/null 2>&1; then
        if stat --version >/dev/null 2>&1; then
          # GNU stat (Linux)
          printf "%s %s" "$(stat -c "%a" "$dir")" "$(stat -c "%u" "$dir")"
        else
          # BSD stat (macOS)
          printf "%s %s" "$(stat -f "%Lp" "$dir")" "$(stat -f "%u" "$dir")"
        fi
      else
        echo "xdg: stat command not available" >&2
        return 1
      fi
    }

    # Get current permissions and ownership
    local stats
    if ! stats=$(_get_file_stats "$XDG_RUNTIME_DIR"); then
      return 1
    fi

    local current_perms="${stats%% *}"
    local current_owner="${stats##* }"

    # Fix permissions if needed
    if [[ "$current_perms" != "700" ]]; then
      echo "xdg: Fixing permissions '$current_perms' → '700' for '$XDG_RUNTIME_DIR'"
      if ! chmod 700 "$XDG_RUNTIME_DIR"; then
        echo "xdg: Failed to set permissions on '$XDG_RUNTIME_DIR'" >&2
        return 1
      fi
    fi

    # Fix ownership if needed
    if [[ "$current_owner" != "$UID" ]]; then
      echo "xdg: Fixing ownership '$current_owner' → '$UID' for '$XDG_RUNTIME_DIR'"
      if ! chown "$USER" "$XDG_RUNTIME_DIR" 2>/dev/null; then
        # Try with sudo if regular chown fails
        if ! sudo chown "$USER" "$XDG_RUNTIME_DIR"; then
          echo "xdg: Failed to change ownership of '$XDG_RUNTIME_DIR'" >&2
          return 1
        fi
      fi
    fi

    # Final verification
    if ! stats=$(_get_file_stats "$XDG_RUNTIME_DIR"); then
      return 1
    fi

    local final_perms="${stats%% *}"
    local final_owner="${stats##* }"

    if [[ "$final_perms" != "700" || "$final_owner" != "$UID" ]]; then
      echo "xdg: Verification failed - perms: $final_perms, owner: $final_owner" >&2
      return 1
    fi

    return 0
    ;;
  setup)
    # Check if user-dirs.dirs exists and source it
    local user_dirs_file="$HOME/.config/user-dirs.dirs"
    if [[ -f "$user_dirs_file" ]]; then
      # Safely source the file
      if ! source "$user_dirs_file"; then
        echo "xdg: Warning - failed to source '$user_dirs_file'" >&2
      fi
    fi

    # Set XDG Base Directory variables
    xdg set "XDG_CONFIG_HOME" "$HOME/.config" || return 1
    xdg set "XDG_CACHE_HOME" "$HOME/.cache" || return 1
    xdg set "XDG_DATA_HOME" "$HOME/.local/share" || return 1
    xdg set "XDG_STATE_HOME" "$HOME/.local/state" || return 1

    # Handle XDG_BIN_HOME (non-standard but commonly used)
    xdg set "XDG_BIN_HOME" "$HOME/.local/bin" || return 1

    # Handle XDG_RUNTIME_DIR specially (validation logic)
    if [[ -z "$XDG_RUNTIME_DIR" || "$XDG_RUNTIME_DIR" =~ ^[[:space:]]*$ ]]; then
      export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
    fi

    # Set XDG User Directory variables (only set defaults, don't create)
    xdg set "XDG_DESKTOP_DIR" "$HOME/Desktop" "false"
    xdg set "XDG_DOWNLOAD_DIR" "$HOME/Downloads" "false"
    xdg set "XDG_DOCUMENTS_DIR" "$HOME/Documents" "false"
    xdg set "XDG_MUSIC_DIR" "$HOME/Music" "false"
    xdg set "XDG_PICTURES_DIR" "$HOME/Pictures" "false"
    xdg set "XDG_VIDEOS_DIR" "$HOME/Movies" "false"

    # Custom directories (create these)
    xdg set "XDG_PROJECTS_DIR" "$HOME/Projects" || return 1
    xdg set "XDG_WORKSPACE_DIR" "$HOME/Work" || return 1

    # Ensure XDG_RUNTIME_DIR has proper permissions and ownership
    xdg ensure-runtime || return 1

    return 0
    ;;
  *)
    echo "xdg: unknown xdg command '$2'" >&2
    echo "Usage: xdg {set|ensure-runtime|setup} [args...]" >&2
    echo "Arguments:"
    echo "  set             : Set an XDG variable"
    echo "  ensure-runtime  : Ensure XDG_RUNTIME_DIR is set up correctly"
    echo "  setup           : Set up XDG variables and directories"
    echo "Examples:"
    echo "  xdg set XDG_CONFIG_HOME /path/to/config"
    echo "  xdg ensure-runtime"
    echo "  xdg setup"
    return 1
    ;;
  esac
}

# Setup XDG variables, directories and permissions
xdg setup

# ZSH DEFAULTS
export ZSH_VERSION="5.9" # zsh --version | cut -d ' ' -f2
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZSH_DATA_DIR="$XDG_DATA_HOME/zsh"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/zsh"
export ZSH_COMPCACHE="$ZSH_CACHE_DIR/compcache"
# ZSH state files
export ZSH_COMPDUMP="$ZSH_COMPCACHE/.zcompdump"
export HISTFILE="$ZSH_DATA_DIR/.zsh_history"
# ZSH custom directories
export ZDOTDIR_OPT="$ZDOTDIR/opt"
export ZDOTDIR_ETC="$ZDOTDIR/etc"
# ZIM variables
# Set where the directory used by Zim will be located (https://zimfw.sh/docs/install)
export ZIM_HOME="$XDG_DATA_HOME/zim"
export SHELL="$(which zsh)"
# Create directories if they don't exist
mkdir -p "$ZDOTDIR" "$ZSH_DATA_DIR" "$ZSH_CACHE_DIR" "$ZSH_COMPCACHE" "$ZIM_HOME"

# Only source this once
if [[ -z "$__HM_ZSH_SESS_VARS_SOURCED" ]]; then
  export __HM_ZSH_SESS_VARS_SOURCED=1
  export MAILCHECK="30"
fi

# Load .zprofile for zsh-specific login settings
[ -f "$ZDOTDIR/.zprofile" ] && source "$ZDOTDIR/.zprofile"