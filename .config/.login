# shellcheck shell=bash disable=SC1094,SC2139,SC2046,SC1090,SC2154,SC2155,SC2206,SC2012,SC1083,SC1091
# ~/.login
#
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists
# https://linux.die.net/sag/shell-startup.html
#
# Contains login specific initialization

# COLORS {
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
[ -z "$TERM" ] && export TERM='xterm-256color'

# CUSTOM DIRS {{
if [ -n "$XDG_USER_DIRS" ] && [ -r "$XDG_USER_DIRS" ]; then
  set -o allexport
  source "$XDG_USER_DIRS"
  set +o allexport
fi
# }}

export VISUAL=$EDITOR
export SUDO_EDITOR=$EDITOR
export GIT_EDITOR="$EDITOR -c 'startinsert'"
export PAGER='less -FREXi'
export BROWSER='open'
export MANROFFOPT='-c'

# LESS {
# https://linuxize.com/post/less-command-in-linux/
export LESS='-RF'
export LESS_HOME=$XDG_CONFIG_HOME/less
export LESSKEY=$LESS_CACHE_HOME/keys
export LESSHISTFILE=$XDG_CACHE_HOME/history/lesshist
export LESS_ADVANCED_PREPROCESSOR=1
# }

# GOPASS {
  # The slightly more awesome standard unix password manager for teams
  # https://github.com/gopasspw/gopass/blob/master/docs/config.md
  export GOPASS_CONFIG_HOME=$XDG_CONFIG_HOME/gopass
  export GOPASS_CONFIG=$GOPASS_CONFIG_HOME/config
  export GOPASS_HOMEDIR=$HOME
  export PASSWORD_STORE_DIR=$XDG_DATA_HOME/gopass/password-store
  export PASSWORD_STORE_CLIP_TIME=45 #secs
  export PASSWORD_STORE_ENABLE_EXTENSIONS=true pass
# }

# TASKWARRIOR {
  # Highly flexible command-line tool to manage TODO lists
  # https://taskwarrior.org
  export TASK_WARRIOR_HOME=$XDG_CONFIG_HOME/tasks
  export TASKOPENRC=$TASK_WARRIOR_HOME/taskopenrc
  export TASKRC=$TASK_WARRIOR_HOME/taskrc
  export TASKDATA=$XDG_DATA_HOME/tasks/data
# }

# GIT-SECRET {
# A bash tool to store private data inside a git repo
# https://git-secret.io/
# https://dev.to/vinitjogani/a-guide-to-git-secret-49g3
export SECRETS_DIR=.secret                   # sets the directory where git-secret stores its files, defaults to .gitsecret. It can be changed to any valid directory name.
export SECRETS_EXTENSION=.secret             # sets the secret files extension
# export SECRETS_GPG_COMMAND=$XDG_BIN_HOME/gpg # sets the gpg alternatives, defaults to gpg
# }

# ASDF {
  # Manage multiple runtime versions with a single CLI tool
  # https://asdf-vm.com/manage/configuration.html#environment-variables
  export ASDF_PLUGIN_VERSION=1.0
  export ASDF_CONFIG_HOME=$XDG_CONFIG_HOME/asdf
  export ASDF_CONFIG_FILE=$ASDF_CONFIG_HOME/asdfrc
  export ASDF_DATA_DIR=$XDG_DATA_HOME/asdf
  export ASDF_DIRENV_VERSION='2.32.2'

  # ASDF-RUBY {{
  # Ruby plugin for asdf version manager
  # https://github.com/asdf-vm/asdf-ruby
  export ASDF_GEM_DEFAULT_PACKAGES_FILE=$XDG_CONFIG_HOME/gem/default-gems
  # }}

  # DIRENV {
  # unclutter your .profile
  # https://github.com/direnv/direnv/wiki/Direnv-bin-dir
  # https://github.com/direnv/direnv/wiki/Customizing-cache-location
  export DIRENV_LOG_FORMAT=''
  # }
# }

# NPM {
  # https://docs.npmjs.com/cli/v7/commands/npm-config
  # https://docs.npmjs.com/cli/v7/configuring-npm/npmrc
  # npm config ls -l
  export NO_UPDATE_NOTIFIER=1 # Opt out notiification https://www.npmjs.com/package/update-notifier#user-settings
  export NPM_CONFIG_HOME=$XDG_CONFIG_HOME/npm
  export NPM_CONFIG_CACHE=$XDG_CACHE_HOME/npm
  export NPM_CONFIG_DEVDIR=$XDG_DATA_HOME/npm/node-gyp
  export NPM_CONFIG_PREFIX=$XDG_DATA_HOME/npm/node_modules
  export NPM_CONFIG_USERCONFIG=$NPM_CONFIG_HOME/config
# }

# NODE REPL {
  # https://nodejs.org/api/repl.html#repl_environment_variable_options
  export NODE_CACHE_HOME=$XDG_CACHE_HOME/node
  export NODE_REPL_HISTORY=$NODE_CACHE_HOME/node_repl_history
  export NODE_REPL_HISTORY_SIZE=1000 # how many lines of history will be persisted if history is available
  export NODE_REPL_MODE=sloppy       # allows non-strict mode code to be run
# }

# PNPM_HOME {
  # https://pnpm.io
  export PNPM_HOME=~/.local/bin
# }

# RIPGREP {
  # A utility that combines the usability of The Silver Searcher with the raw speed of grep
  # https://github.com/BurntSushi/ripgrep
  export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep
# }

# EXA {
  # A modern replacement for ls
  # https://the.exa.website/features/colours
  export EXA_COLORS="ln=04;01;38;5;205:ex=01;38;5;10:bl=38;5;220:ga=36:gd=31:gm=33:gn=38;5;160:gr=34:gt=37:gu=35;1:gv=33:gw=1;34:gx=1;32:lc=37:sb=32:sf=37:sn=32:su=37:tr=34:tw=1;34:tx=1;35:ue=1;35:un=38;5;160:ur=1;32:uu=1;36:uw=1;34:ux=1;32"
# }

# JQ {
  # A lightweight and flexible command-line JSON processor
  # https://stedolan.github.io/jq/manual/#Advancedfeatures
  export JQ_COLORS='1;30:0;37:0;37:0;37:0;32:1;37:1;37'
# }

# WATCHMAN {
  # Watches files and records, or triggers actions, when they change.
  # https://facebook.github.io/watchman/
  export WATCHMAN_CONFIG_FILE=$XDG_CONFIG_HOME/watchman/config.json
# }

# CHEAT {
  # Create and view interactive cheatsheets on the command-line
  # https://github.com/cheat/cheat
  export CHEAT_HOME=$XDG_CONFIG_HOME/cheat
  export CHEAT_GISTS=$CHEAT_HOME/gists
# }

# DOC_OPTS {
  # Command-line interface description language
  # https://github.com/docopt/docopts
  # http://docopt.org/
  export DOC_OPTS=$XDG_CONFIG_HOME/bin/extract_docopt
# }

# BAT {
  # A cat(1) clone with wings
  # https://github.com/sharkdp/bat#configuration-file
  export BAT_CONFIG_HOME=$XDG_CONFIG_HOME/bat
  export BAT_CONFIG_PATH=$BAT_CONFIG_HOME/bat.conf
# }

# NAVI {
  # An interactive cheatsheet tool for the command-line
  # https://github.com/denisidoro/navi
  # If the cheats directory in the user's directory does not exist, navi uses this path (if it exists), as a fallback location to look for cheat files.
  # Use case: system-wide installed, shared used cheatsheets folder.
  # export NAVI_PATH=$XDG_DATA_HOME/tasks # directory path value

  # If the config.yaml file in the user's directory does not exist, navi uses this path (if it exists), as a fallback location to look for a configuration file.
  # Use case: system-wide installed, shared used configuration file.
  export NAVI_CONFIG=$XDG_CONFIG_HOME/navi/config.yml # file path value
# }

# NNN {
  # The unorthodox terminal file manager
  # https://github.com/jarun/nnn
  export NNN_HOME=$XDG_CONFIG_HOME/nnn
  export NNN_TMPFILE=$NNN_HOME/.lastd
  export NNN_OPENER=$NNN_HOME/plugins/nuke
  export NNN_PLUG='o:fzopen;m:nmount'
  export NNN_TRASH=1
  export NNN_COLORS='4444' # blue
  export NNN_BMS='d:~/Documents;D:~/Downloads;w:~/Work'
  export NNN_FIFO='/tmp/nnn.fifo'
  export NNN_PLUG_DEFAULT='f:fzopen;v:imgview;g:getplugs;c:diffs;d:dragdrop'
  export NNN_PLUG_INLINE="x:!chmod u+x $nnn;t:-!tree -a $nnn;u:!unlink $nnn"
  export NNN_PLUG="$NNN_PLUG_DEFAULT;$NNN_PLUG_INLINE"
# }

# STARSHIP {
  # The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  # https://starship.rs/config/#configuration
  export STARSHIP_CONFIG_HOME=$XDG_CONFIG_HOME/starship
  export STARSHIP_CONFIG=$STARSHIP_CONFIG_HOME/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
# }

# GOMPLATE_CONFIG {
  # Go template configuration
  # https://docs.gomplate.ca
  export GOMPLATE_HOME=$XDG_CONFIG_HOME/gomplate
  export GOMPLATE_TEMPLATES=$GOMPLATE_HOME/templates
# }

# FZF {
  # A command-line fuzzy finder
  # https://github.com/junegunn/fzf
  export FZF_COMPLETION_TRIGGER='**'
  export FZF_DEFAULT_COMMAND='fd --type f --ignore-case --follow --color=always --hidden --exclude .git'
  export FZF_DEFAULT_OPTS="--inline-info --ansi --height 90% --marker='✔' --pointer='▶' --keep-right --margin=1,1 --color=dark --prompt='❯ ' --color=fg:#f8f8f2,bg:-1,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4"
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always {}' --bind 'ctrl-e:execute(echo {+} | xargs -o '${EDITOR}' -)+abort' --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'"
  export FZF_CTRL_R_OPTS="--header='[y]ank [e]edit' --preview 'bat --color=always {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview'"
  export FZF_ALT_C_COMMAND="fd --type directory"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
# }

# RUST {
  # display RUST backtrace
  # export RUST_BACKTRACE=1
  # Some details are omitted, run with `RUST_BACKTRACE=full` for a verbose backtrace.
  export RUST_BACKTRACE=full
# }

# HELIX {
  # A post-modern modal text editor: http://helix-editor.com
  # https://docs.helix-editor.com/install.html
  export HELIX_RUNTIME=$XDG_DATA_HOME/helix/runtime
# }

# DIRCOLORS {
  # enable color support of ls and also add handy aliases
  if type dircolors >/dev/null; then
    if [ -r ~/.dircolors ]; then
      eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
  fi
# }

# TEALDEER {
  # Very fast implementation of tldr in Rust
  # https://github.com/dbrgn/tealdeer#configuration
  export TEALDEER_CONFIG_DIR=${XDG_CONFIG_HOME}/tealdeer
  alias tl='tldr --list | fzf --exact --ansi | xargs tldr'
# }

# CHEAT {
  # Create and view interactive cheatsheets on the command-line
  # https://github.com/cheat/cheat#autocompletion
  export CHEAT_USE_FZF=true
# }

# SHELDON {
  # https://sheldon.cli.rs
  # Sheldon is a fast, configurable, command-line tool to manage your shell plugins.
  if type sheldon >/dev/null; then
    export SHELDON_DATA_DIR=$XDG_DATA_HOME/sheldon
    export SHELDON_DATA_REPOS=$SHELDON_DATA_DIR/repos/github.com
    export SHELDON_PROFILE=fig # Specify the profile to match plugins against.
    source <(sheldon source)
  fi
# }
