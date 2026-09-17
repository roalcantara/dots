#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC1094,SC2139,SC2046,SC1090,SC2154,SC2155,SC2206,SC2012,SC1083,SC1091,SC2086,SC2034

# ~/.zshenv
# Sourced on all invocations of the shell - unless the -f option is set
# Contains commands and set variables that should be available to other programs
# zsh --sourcetrace: Show full path of sourced files
# http://zsh.sourceforge.net/Intro/intro_3.html | https://github.com/jimeh/dotfiles/blob/main/zshenv

## 🔖 PROFILING/TRACING/DEBUGGING {
# To enable profilling run:
#   z_prof=1 "$SHELL" -ilc exit
#   z_prof=1; for _ in $(seq 1 10); do /usr/bin/time "${SHELL}" -ilc exit; done
# To enable tracing run:
#   z_prof=1 z_trace=1 "$SHELL" -ilc exit
[ -n "$z_prof" ] && zmodload zsh/zprof
if [[ -n "$z_trace" ]]; then
  # Set a timestamp and script location in PS4 for better trace readability
  PS4=$'%D{%H:%M:%S} ${(%):-%N:%i}> ' # Adds timestamp, filename, & line number
  # Set logging output to a dedicated log file with a unique session ID
  exec 3>&2 2>>$HOME/.config/zsh/tmp/benchmark.$$.start.log
  setopt xtrace prompt_subst
fi

## 🔒 PREVENT COMPIINIT CALLS {
# Set these variables BEFORE any system files are sourced (e.g. NO_RCS)
# It prevents compinit from being called by other sources
export skip_global_compinit=1
export NO_GLOBAL_RCS=1
export MAILCHECK=0
export ZIM_DISABLE_AUTOLOAD=1
export DEBIAN_PREVENT_KEYBOARD_CHANGES=1
export NVM_LAZY_LOAD=1
export NVM_COMPLETION=true
# }

## 🔒 PREVENT SYSTEM-WIDE RCS FILES FROM BEING SOURCED {
# 💡 compinit override removed; NO_RCS prevents system-wide files from loading
# It ensures only our user config is loaded, preventing compinit conflicts
setopt NO_RCS
setopt NO_MAILWARN
setopt NO_MAILWARNING
setopt NO_GLOBAL_RCS
# }

## 🌐 i18n {
# The values that the environment variables may be assigned are not restricted;
# Environment and argument space is limited by {ARG_MAX}.
# Avoid conflicts with commonly exported environment variables.
# https://pubs.opengroup.org/onlinepubs/7908799/xbd/envvar.html
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_COLLATE=C
# }

# To enable debugging run:
#   z_debug=1 "$SHELL" -ilc exit
# Check if compinit is being called at the right time
# https://github.com/zimfw/zimfw/wiki/Troubleshooting#completion-is-not-working
if [[ -n "$z_debug" ]]; then
  autoload -Uz +X compinit
  functions[compinit]=$'print -u2 \'compinit being called at \'${funcfiletrace[1]}
  '${functions[compinit]}
fi
# }

# Load XDG environment variables from .profile
if [ -f $HOME/.profile ]; then
  source $HOME/.profile
fi

## 📦 TOOL ENVIRONMENT {
# Pure environment: no output, no tty access, no subprocesses.
# Lives here (not .zprofile) so non-login shells inherit it too.

# LESS {
  # https://linuxize.com/post/less-command-in-linux/
  export LESS=${LESS:-"-RF"}
  export LESS_HOME=${LESS_HOME:-$XDG_CONFIG_HOME/less}
  export LESS_CACHE_HOME=${LESS_CACHE_HOME:-$XDG_CACHE_HOME/less}
  export LESSKEY=${LESSKEY:-$LESS_CACHE_HOME/keys}
  export LESSHISTFILE=${LESSHISTFILE:-$XDG_CACHE_HOME/history/lesshist}
  export LESS_ADVANCED_PREPROCESSOR=${LESS_ADVANCED_PREPROCESSOR:-1}
# }

# MISE | https://mise.jdx.dev {
  # A polyglot tool version manager. It replaces tools like asdf, nvm, pyenv, rbenv, etc.
  # Set the global configuration file path
  export MISE_GLOBAL_CONFIG_FILE=${MISE_GLOBAL_CONFIG_FILE:-$XDG_CONFIG_HOME/mise/config.toml}
  # Set the cache directory path
  export MISE_CACHE_DIR=${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}
  # Set the data directory path
  export MISE_DATA_HOME=${MISE_DATA_HOME:-$XDG_DATA_HOME/mise}
  # Use the built-in Rust evaluator for HK (https://hk.jdx.dev/getting_started.html#installation | https://hk.jdx.dev/pkl_introduction.html)
  export HK_PKL_BACKEND=pklr
# }

# STARSHIP | https://starship.rs | https://starship.rs/config/#configuration {
  # The minimal, blazing-fast, and infinitely customizable prompt for any shell
  export STARSHIP_CONFIG_HOME=${STARSHIP_CONFIG_HOME:-$XDG_CONFIG_HOME/starship}
  export STARSHIP_CONFIG=${STARSHIP_CONFIG:-$STARSHIP_CONFIG_HOME/starship.toml}
  export STARSHIP_CACHE=${STARSHIP_CACHE:-$XDG_CACHE_HOME/starship}
# }

# GNUPG | https://gnupg.org {
  # The GNU Privacy Guard; Needed for git PGP-signed commits also needed for sops
  # https://gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
  export GNUPGHOME=${GNUPGHOME:-$XDG_CONFIG_HOME/gnupg}
# }

# NPM | https://docs.npmjs.com {
  # The Node Package Manager
  # `npm config list` => List all main npm settings
  # `npm config ls -l` => List all npm settings
  # Path to the personal npm configuration file
  # npm will read configuration from this file instead of the default location ($HOME/.npmrc)
  # https://docs.npmjs.com/cli/v7/using-npm/config#userconfig
  export NPM_CONFIG_USERCONFIG=${NPM_CONFIG_USERCONFIG:-$XDG_CONFIG_HOME/npm/.npmrc}
  # Set where global packages are installed when running `npm install -g [package]`.
  # Global binaries go to ${prefix}/bin and global packages to ${prefix}/lib/node_modules
  export NPM_CONFIG_PREFIX=${NPM_CONFIG_PREFIX:-$XDG_DATA_HOME/npm}
  # Path to npm's cache directory, which includes logs ($HOME/.npm)
  export NPM_CONFIG_CACHE=${NPM_CONFIG_CACHE:-$XDG_CACHE_HOME/npm}
  # Opt out of update notifications https://npmjs.com/package/update-notifier#user-settings
  export NO_UPDATE_NOTIFIER=${NO_UPDATE_NOTIFIER:-1}
  # NODE REPL | https://nodejs.org/api/repl.html#repl_environment_variable_options
  export NODE_NO_WARNINGS=${NODE_NO_WARNINGS:-1} # silence all process warnings
# }

# RUBY | https://ruby-lang.org {
  # The Ruby Package Manager | 💡 gem env gempath
  # https://guides.rubygems.org/command-reference/#gem-environment
  export GEM_HOME=${GEM_HOME:-$XDG_DATA_HOME/gems}

  # RBENV | The Ruby version manager
  # https://github.com/rbenv/rbenv
  export RBENV_ROOT=${RBENV_ROOT:-$XDG_DATA_HOME/rbenv}
# }

# CARGO | https://doc.rust-lang.org/cargo | https://doc.rust-lang.org/cargo/guide/cargo-home.html {
  # Rust package manager that downloads dependencies, compiles and distributes packages
  export CARGO_HOME=${CARGO_HOME:-$XDG_DATA_HOME/cargo}
  export RUSTUP_HOME=${RUSTUP_HOME:-$XDG_DATA_HOME/rustup}
# }

# PNPM | https://pnpm.io {
  # Fast, disk space efficient package manager
  export PNPM_HOME=${PNPM_HOME:-$XDG_DATA_HOME/pnpm}
# }

# JQ | https://stedolan.github.io/jq {
  # A lightweight and flexible command-line JSON processor
  # https://stedolan.github.io/jq/manual/#Advancedfeatures
  export JQ_COLORS=${JQ_COLORS:-"1;30:0;37:0;37:0;37:0;32:1;37:1;37"}
# }

# RIPGREP | https://github.com/BurntSushi/ripgrep {
  # A utility that combines the usability of The Silver Searcher with the raw speed of grep
  export RIPGREP_CONFIG_PATH=${RIPGREP_CONFIG_PATH:-$XDG_CONFIG_HOME/ripgrep/.ripgreprc}
# }

# BAT | https://github.com/sharkdp/bat {
  # A cat(1) clone with wings
  export BAT_CONFIG_HOME=${BAT_CONFIG_HOME:-$XDG_CONFIG_HOME/bat}
  export BAT_CONFIG_PATH=${BAT_CONFIG_PATH:-$BAT_CONFIG_HOME/bat.conf}
# }

# GLOW | https://charm.sh/docs/glow {
  # A terminal-based markdown reader, renderer, and formatter
  export GLOW_CONFIG_PATH=${GLOW_CONFIG_PATH:-$XDG_CONFIG_HOME/glow/conf.yml}
# }

# GOPASS | https://github.com/gopasspw/gopass {
  # The slightly more awesome standard unix password manager for teams
  export GOPASS_CONFIG_HOME=${GOPASS_CONFIG_HOME:-$XDG_CONFIG_HOME/gopass}
  export GOPASS_CONFIG=${GOPASS_CONFIG:-$GOPASS_CONFIG_HOME/config}
  export GOPASS_HOMEDIR=${GOPASS_HOMEDIR:-$HOME}
  export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-$XDG_DATA_HOME/gopass/password-store}
  export PASSWORD_STORE_CLIP_TIME=${PASSWORD_STORE_CLIP_TIME:-45} #secs
  export PASSWORD_STORE_ENABLE_EXTENSIONS=${PASSWORD_STORE_ENABLE_EXTENSIONS:-true}
# }

# GITLINT | https://jorisroovers.com/gitlint {
  # Gitlint checks your commit messages for style and content
  export GITLINT_CONFIG=${GITLINT_CONFIG:-$XDG_CONFIG_HOME/gitlint/gitlint.cfg}
# }

# WAKATIME | https://github.com/wakatime/wakatime {
  # WakaTime command line interface
  export WAKATIME_HOME=${WAKATIME_HOME:-$XDG_CONFIG_HOME/wakatime}
# }

# GO | https://go.dev {
  # Configure the location of the Go workspace
  export GOPATH=${GOPATH:-$XDG_DATA_HOME/go}
# }

# PUPPETEER | https://pptr.dev/api/puppeteer.configuration {
  export PUPPETEER_CONFIG=${PUPPETEER_CONFIG:-$XDG_CONFIG_HOME/puppeter/config.yml}
  export PUPPETEER_CACHE_DIR=${PUPPETEER_CACHE_DIR:-$XDG_CACHE_HOME/puppeteer}
  export PUPPETEER_TMP_DIR=${PUPPETEER_TMP_DIR:-$XDG_DATA_HOME/puppeteer}
  export PUPPETEER_SKIP_DOWNLOAD=false
  export PUPPETEER_TIMEOUT=30000
# }
# }

# if .zprofile exists, source it (after XDG setup so ZDOTDIR is available)
# Skip when non-interactive (e.g. `git branches` runs `zsh git-branches`) to avoid loading
# .zshrc/starship/ZIM in subprocesses — prevents flicker and keeps alias fast
if [[ (-o login || -o interactive) && $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zprofile" ]]; then
  source "$ZDOTDIR/.zprofile"
fi
