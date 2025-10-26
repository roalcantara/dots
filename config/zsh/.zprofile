#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

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
  # Set the global configuration directory path
  export MISE_GLOBAL_CONFIG_DIR=${MISE_GLOBAL_CONFIG_DIR:-$XDG_DATA_HOME/mise}
  # Set the global configuration file path
  export MISE_GLOBAL_CONFIG_FILE=${MISE_GLOBAL_CONFIG_FILE:-$MISE_GLOBAL_CONFIG_DIR/config.toml}
  # Set the cache directory path
  export MISE_CACHE_DIR=${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}
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
  export GPG_TTY=${GPG_TTY:-"$(tty)"}
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

# GOPASS | https://gopass.pw {
  # The missing password manager for teams | Load API keys from gopass if available
  # WITHOUT ==> dots zsh --prof avg => │ USER:40ms  │ SYSTEM:20ms │ CPU:91% │ TOTAL:69ms │
  # if _has_command gopass; then
  #   WITH => dots zsh --prof avg => │ USER:765ms  │ SYSTEM:88ms │ CPU:92% │ TOTAL:921ms │
  #   export ANTHROPIC_API_KEY=$(gopass show -n --password tokens/anthropic.com)
  #   export GEMINI_API_KEY=$(gopass show -n --password tokens/gemini.google.com)
  # fi
# }

# if .zshrc exists, source it
if [[ $TERM_PROGRAM != "WarpTerminal" && -r "$ZDOTDIR/.zshrc" ]]; then
  source "$ZDOTDIR/.zshrc"
fi
