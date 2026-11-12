# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/roalcantara/.docker/bin"
# End of Docker Desktop section.

## 🚀 XDG|ZSH ENVIRONMENT SETUP & OPTIMIZATION {
# ⚡️ XDG ENVIRONMENT SETUP - Smart caching system for BLAZING FAST shell startup
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
# Keep the session's own runtime dir: on Linux, systemd sets /run/user/$UID, where the user D-Bus lives (overriding it
# breaks GNOME Terminal after a reboot: "Failed to connect to user scope bus"). macOS and containers get a fallback.
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/runtime-$UID}
export XDG_LOCAL_DIR=$HOME/.local
export XDG_LOCAL_BIN_DIR=$HOME/.local/bin
export XDG_PROJECTS_DIR=$HOME/Projects
export XDG_WORKSPACE_DIR=$HOME/Work
export XDG_DESKTOP_DIR=$HOME/Desktop
export XDG_DOWNLOAD_DIR=$HOME/Downloads
export XDG_TEMPLATES_DIR=$HOME/Templates
export XDG_PUBLICSHARE_DIR=$HOME/Public
export XDG_DOCUMENTS_DIR=$HOME/Documents
export XDG_MUSIC_DIR=$HOME/Music
export XDG_PICTURES_DIR=$HOME/Pictures
export XDG_VIDEOS_DIR=$HOME/Movies
export ZDOTDIR=$HOME/.config/zsh
export ZSH_DATA_DIR=$HOME/.local/share/zsh
export HISTFILE=$HOME/.local/share/zsh/.zsh_history
export ZSH_CACHE_DIR=$HOME/.cache/zsh
export ZSH_COMPCACHE=$HOME/.cache/zsh/compcache
export ZSH_COMPDUMP=$HOME/.cache/zsh/compcache/.zcompdump
export ZIM_HOME=$HOME/.local/state/zim
export zdumpfile=$HOME/.cache/zsh/compcache/.zcompdump
mkdir -p $ZSH_DATA_DIR $ZSH_COMPCACHE $ZIM_HOME
# }

# LM Studio CLI (lms), when installed. Its installer writes a copy with the home folder hardcoded.
if [ -d "$HOME/.lmstudio/bin" ]; then
  export PATH="$PATH:$HOME/.lmstudio/bin"
fi

