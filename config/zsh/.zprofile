#!/usr/bin/env zsh

# # ~/.zprofile
# Sourced in login shells - BEFORE `.zshrc`
# Contains commands that should be executed only in login shells
# http://zsh.sourceforge.net/Intro/intro_3.html

# Directory stack size
export DIRSTACKSIZE=100
export PAGER='less -FREXi'
export BROWSER='open'
export MANROFFOPT='-c'

# Redirects stdout (file descriptor 1) to /dev/null
# Then redirects stderr (file descriptor 2) to wherever stdout is going (which is now /dev/null)
# Works in all POSIX-compliant shells (sh, dash, bash, zsh, etc.)
_has_command() {
  command -v "$1" >/dev/null 2>&1
}

# MISE {
  # A polyglot tool version manager. It replaces tools like asdf, nvm, pyenv, rbenv, etc.
  # https://mise.jdx.dev
  if [[ -e $XDG_DATA_HOME/mise/config.toml ]]; then
    export MISE_GLOBAL_CONFIG_FILE=$XDG_DATA_HOME/mise/config.toml
  fi

  if _has_command mise; then
    export MISE_CACHE_DIR=$XDG_CACHE_HOME/mise
    eval "$(mise activate zsh --yes --quiet --shims)"
  fi
# }

# HOMEBREW {
  # https://brew.sh
  # Determine Homebrew prefix based on OS and architecture
  if [[ -d /opt/homebrew || -d /home/linuxbrew/.linuxbrew || -d /usr/local/Homebrew || -e /usr/local/bin/brew ]]; then
    export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:=${HOMEBREW_PREFIX:-$(if [ -d /opt/homebrew ]; then echo "/opt/homebrew"; elif [ -d /home/linuxbrew/.linuxbrew ]; then echo "/home/linuxbrew/.linuxbrew"; else echo "/usr/local"; fi)}}
    export HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
    export HOMEBREW_SHARE=$HOMEBREW_PREFIX/share
    export HOMEBREW_NO_ENV_HINTS=1                                 # Hide hints
    export HOMEBREW_NO_ANALYTICS=1                                 # Disabled analytics
    export HOMEBREW_BAT=true                                       # Use bat for the brew cat command
    export HOMEBREW_BAT_THEME=dracula                              # Use this as the bat theme for syntax highlighting
    export HOMEBREW_BUNDLE_DUMP_NO_VSCODE=1                        # Don't dump vscode extensions
    export HOMEBREW_BUNDLE_FILE=$XDG_CONFIG_HOME/homebrew/Brewfile # https://docs.brew.sh/Manpage#bundle-subcommand
    eval "$("$HOMEBREW_BIN"/brew shellenv)"
  fi
# }

# COLORS / TERM / SHELL {
  export CLICOLOR=1
  export LSCOLORS=ExFxBxDxCxegedabagacad
  export LS_COLORS='bd=0;38;2;154;237;254;48;2;51;51;51:su=0:rs=0:cd=0;38;2;255;106;193;48;2;51;51;51:sg=0:mh=0:*~=0;38;2;102;102;102:mi=0;38;2;0;0;0;48;2;255;92;87:ex=1;38;2;255;92;87:do=0;38;2;0;0;0;48;2;255;106;193:ow=0:tw=0:ca=0:or=0;38;2;0;0;0;48;2;255;92;87:so=0;38;2;0;0;0;48;2;255;106;193:pi=0;38;2;0;0;0;48;2;87;199;255:st=0:no=0:ln=0;38;2;255;106;193:fi=0:di=0;38;2;87;199;255:*.p=0;38;2;90;247;142:*.c=0;38;2;90;247;142:*.m=0;38;2;90;247;142:*.a=1;38;2;255;92;87:*.h=0;38;2;90;247;142:*.o=0;38;2;102;102;102:*.d=0;38;2;90;247;142:*.z=4;38;2;154;237;254:*.r=0;38;2;90;247;142:*.t=0;38;2;90;247;142:*.pm=0;38;2;90;247;142:*.hh=0;38;2;90;247;142:*.cr=0;38;2;90;247;142:*.7z=4;38;2;154;237;254:*.nb=0;38;2;90;247;142:*.pp=0;38;2;90;247;142:*css=0;38;2;90;247;142:*.md=0;38;2;243;249;157:*.kt=0;38;2;90;247;142:*.sh=0;38;2;90;247;142:*.js=0;38;2;90;247;142:*.td=0;38;2;90;247;142:*.ps=0;38;2;255;92;87:*.gz=4;38;2;154;237;254:*.di=0;38;2;90;247;142:*.hi=0;38;2;102;102;102:*.cs=0;38;2;90;247;142:*.as=0;38;2;90;247;142:*.hs=0;38;2;90;247;142:*.xz=4;38;2;154;237;254:*.jl=0;38;2;90;247;142:*.vb=0;38;2;90;247;142:*.mn=0;38;2;90;247;142:*.go=0;38;2;90;247;142:*.el=0;38;2;90;247;142:*.bz=4;38;2;154;237;254:*.lo=0;38;2;102;102;102:*.ko=1;38;2;255;92;87:*.bc=0;38;2;102;102;102:*.py=0;38;2;90;247;142:*.cc=0;38;2;90;247;142:*.so=1;38;2;255;92;87:*.rm=0;38;2;255;180;223:*.pl=0;38;2;90;247;142:*.fs=0;38;2;90;247;142:*.ex=0;38;2;90;247;142:*.gv=0;38;2;90;247;142:*.ts=0;38;2;90;247;142:*.rs=0;38;2;90;247;142:*.la=0;38;2;102;102;102:*.rb=0;38;2;90;247;142:*.ml=0;38;2;90;247;142:*.cp=0;38;2;90;247;142:*.ui=0;38;2;243;249;157:*.wv=0;38;2;255;180;223:*.ll=0;38;2;90;247;142:*.tex=0;38;2;90;247;142:*.epp=0;38;2;90;247;142:*.fsx=0;38;2;90;247;142:*.sty=0;38;2;102;102;102:*.mir=0;38;2;90;247;142:*.erl=0;38;2;90;247;142:*.zst=4;38;2;154;237;254:*.eps=0;38;2;255;180;223:*.tml=0;38;2;243;249;157:*.vcd=4;38;2;154;237;254:*.awk=0;38;2;90;247;142:*hgrc=0;38;2;165;255;195:*TODO=1:*.log=0;38;2;102;102;102:*.tgz=4;38;2;154;237;254:*.tmp=0;38;2;102;102;102:*.sbt=0;38;2;90;247;142:*.aif=0;38;2;255;180;223:*.m4v=0;38;2;255;180;223:*.bat=1;38;2;255;92;87:*.fnt=0;38;2;255;180;223:*.bbl=0;38;2;102;102;102:*.tif=0;38;2;255;180;223:*.wmv=0;38;2;255;180;223:*.ipp=0;38;2;90;247;142:*.bin=4;38;2;154;237;254:*.bmp=0;38;2;255;180;223:*.blg=0;38;2;102;102;102:*.exe=1;38;2;255;92;87:*.cxx=0;38;2;90;247;142:*.toc=0;38;2;102;102;102:*.swp=0;38;2;102;102;102:*.dpr=0;38;2;90;247;142:*.deb=4;38;2;154;237;254:*.xlr=0;38;2;255;92;87:*.flv=0;38;2;255;180;223:*.vim=0;38;2;90;247;142:*.htc=0;38;2;90;247;142:*.pid=0;38;2;102;102;102:*.img=4;38;2;154;237;254:*.pod=0;38;2;90;247;142:*.ps1=0;38;2;90;247;142:*.wav=0;38;2;255;180;223:*.pgm=0;38;2;255;180;223:*.bz2=4;38;2;154;237;254:*.xls=0;38;2;255;92;87:*.zsh=0;38;2;90;247;142:*.wma=0;38;2;255;180;223:*.swf=0;38;2;255;180;223:*.avi=0;38;2;255;180;223:*.gvy=0;38;2;90;247;142:*.vob=0;38;2;255;180;223:*.cfg=0;38;2;243;249;157:*.ini=0;38;2;243;249;157:*.psd=0;38;2;255;180;223:*.ogg=0;38;2;255;180;223:*.php=0;38;2;90;247;142:*.iso=4;38;2;154;237;254:*.tar=4;38;2;154;237;254:*.m4a=0;38;2;255;180;223:*.dll=1;38;2;255;92;87:*.cgi=0;38;2;90;247;142:*.com=1;38;2;255;92;87:*.csx=0;38;2;90;247;142:*.ics=0;38;2;255;92;87:*.bib=0;38;2;243;249;157:*.fls=0;38;2;102;102;102:*.jar=4;38;2;154;237;254:*.def=0;38;2;90;247;142:*.sxw=0;38;2;255;92;87:*.arj=4;38;2;154;237;254:*.apk=4;38;2;154;237;254:*.pdf=0;38;2;255;92;87:*.htm=0;38;2;243;249;157:*.doc=0;38;2;255;92;87:*.zip=4;38;2;154;237;254:*.png=0;38;2;255;180;223:*.out=0;38;2;102;102;102:*.dot=0;38;2;90;247;142:*.elm=0;38;2;90;247;142:*.bst=0;38;2;243;249;157:*.lua=0;38;2;90;247;142:*.ods=0;38;2;255;92;87:*.clj=0;38;2;90;247;142:*.dmg=4;38;2;154;237;254:*.xcf=0;38;2;255;180;223:*.tbz=4;38;2;154;237;254:*.hpp=0;38;2;90;247;142:*.pro=0;38;2;165;255;195:*.ilg=0;38;2;102;102;102:*.git=0;38;2;102;102;102:*.pyo=0;38;2;102;102;102:*.tcl=0;38;2;90;247;142:*.rar=4;38;2;154;237;254:*.ppt=0;38;2;255;92;87:*.bcf=0;38;2;102;102;102:*.rtf=0;38;2;255;92;87:*.xml=0;38;2;243;249;157:*.csv=0;38;2;243;249;157:*.pps=0;38;2;255;92;87:*.mp3=0;38;2;255;180;223:*.asa=0;38;2;90;247;142:*.sql=0;38;2;90;247;142:*.fsi=0;38;2;90;247;142:*.ind=0;38;2;102;102;102:*.yml=0;38;2;243;249;157:*.cpp=0;38;2;90;247;142:*.inl=0;38;2;90;247;142:*.mkv=0;38;2;255;180;223:*.ltx=0;38;2;90;247;142:*.idx=0;38;2;102;102;102:*.bak=0;38;2;102;102;102:*.c++=0;38;2;90;247;142:*.bsh=0;38;2;90;247;142:*.kts=0;38;2;90;247;142:*.rst=0;38;2;243;249;157:*.hxx=0;38;2;90;247;142:*.pyc=0;38;2;102;102;102:*.fon=0;38;2;255;180;223:*.gif=0;38;2;255;180;223:*.jpg=0;38;2;255;180;223:*.pas=0;38;2;90;247;142:*.inc=0;38;2;90;247;142:*.sxi=0;38;2;255;92;87:*.rpm=4;38;2;154;237;254:*.svg=0;38;2;255;180;223:*.kex=0;38;2;255;92;87:*.nix=0;38;2;243;249;157:*.mpg=0;38;2;255;180;223:*.mp4=0;38;2;255;180;223:*.ttf=0;38;2;255;180;223:*.exs=0;38;2;90;247;142:*.ppm=0;38;2;255;180;223:*.mov=0;38;2;255;180;223:*.pyd=0;38;2;102;102;102:*.txt=0;38;2;243;249;157:*.mid=0;38;2;255;180;223:*.xmp=0;38;2;243;249;157:*.aux=0;38;2;102;102;102:*.bag=4;38;2;154;237;254:*.tsx=0;38;2;90;247;142:*.mli=0;38;2;90;247;142:*.odt=0;38;2;255;92;87:*.pkg=4;38;2;154;237;254:*.otf=0;38;2;255;180;223:*.pbm=0;38;2;255;180;223:*.odp=0;38;2;255;92;87:*.h++=0;38;2;90;247;142:*.dox=0;38;2;165;255;195:*.ico=0;38;2;255;180;223:*.html=0;38;2;243;249;157:*.mpeg=0;38;2;255;180;223:*.bash=0;38;2;90;247;142:*.lisp=0;38;2;90;247;142:*.opus=0;38;2;255;180;223:*.h264=0;38;2;255;180;223:*.yaml=0;38;2;243;249;157:*.diff=0;38;2;90;247;142:*.docx=0;38;2;255;92;87:*.webm=0;38;2;255;180;223:*.tiff=0;38;2;255;180;223:*.orig=0;38;2;102;102;102:*.java=0;38;2;90;247;142:*.jpeg=0;38;2;255;180;223:*.make=0;38;2;165;255;195:*.tbz2=4;38;2;154;237;254:*.rlib=0;38;2;102;102;102:*.hgrc=0;38;2;165;255;195:*.pptx=0;38;2;255;92;87:*.xlsx=0;38;2;255;92;87:*.toml=0;38;2;243;249;157:*.lock=0;38;2;102;102;102:*.conf=0;38;2;243;249;157:*.flac=0;38;2;255;180;223:*.psm1=0;38;2;90;247;142:*.less=0;38;2;90;247;142:*.purs=0;38;2;90;247;142:*.epub=0;38;2;255;92;87:*.dart=0;38;2;90;247;142:*.psd1=0;38;2;90;247;142:*.json=0;38;2;243;249;157:*.fish=0;38;2;90;247;142:*README=0;38;2;40;42;54;48;2;243;249;157:*.class=0;38;2;102;102;102:*.cabal=0;38;2;90;247;142:*.dyn_o=0;38;2;102;102;102:*.ipynb=0;38;2;90;247;142:*.patch=0;38;2;90;247;142:*.xhtml=0;38;2;243;249;157:*.cache=0;38;2;102;102;102:*shadow=0;38;2;243;249;157:*.shtml=0;38;2;243;249;157:*.scala=0;38;2;90;247;142:*.swift=0;38;2;90;247;142:*.toast=4;38;2;154;237;254:*passwd=0;38;2;243;249;157:*.mdown=0;38;2;243;249;157:*.cmake=0;38;2;165;255;195:*.flake8=0;38;2;165;255;195:*.groovy=0;38;2;90;247;142:*.config=0;38;2;243;249;157:*.gradle=0;38;2;90;247;142:*.dyn_hi=0;38;2;102;102;102:*LICENSE=0;38;2;153;153;153:*COPYING=0;38;2;153;153;153:*INSTALL=0;38;2;40;42;54;48;2;243;249;157:*TODO.md=1:*.matlab=0;38;2;90;247;142:*.ignore=0;38;2;165;255;195:*.desktop=0;38;2;243;249;157:*.gemspec=0;38;2;165;255;195:*Makefile=0;38;2;165;255;195:*setup.py=0;38;2;165;255;195:*Doxyfile=0;38;2;165;255;195:*TODO.txt=1:*.DS_Store=0;38;2;102;102;102:*.fdignore=0;38;2;165;255;195:*.kdevelop=0;38;2;165;255;195:*README.md=0;38;2;40;42;54;48;2;243;249;157:*configure=0;38;2;165;255;195:*.markdown=0;38;2;243;249;157:*.cmake.in=0;38;2;165;255;195:*COPYRIGHT=0;38;2;153;153;153:*.rgignore=0;38;2;165;255;195:*.gitignore=0;38;2;165;255;195:*CODEOWNERS=0;38;2;165;255;195:*.gitconfig=0;38;2;165;255;195:*SConstruct=0;38;2;165;255;195:*.localized=0;38;2;102;102;102:*Dockerfile=0;38;2;243;249;157:*.scons_opt=0;38;2;102;102;102:*INSTALL.md=0;38;2;40;42;54;48;2;243;249;157:*.synctex.gz=0;38;2;102;102;102:*Makefile.am=0;38;2;165;255;195:*INSTALL.txt=0;38;2;40;42;54;48;2;243;249;157:*Makefile.in=0;38;2;102;102;102:*.gitmodules=0;38;2;165;255;195:*MANIFEST.in=0;38;2;165;255;195:*LICENSE-MIT=0;38;2;153;153;153:*.travis.yml=0;38;2;90;247;142:*.fdb_latexmk=0;38;2;102;102;102:*configure.ac=0;38;2;165;255;195:*appveyor.yml=0;38;2;90;247;142:*CONTRIBUTORS=0;38;2;40;42;54;48;2;243;249;157:*.applescript=0;38;2;90;247;142:*.clang-format=0;38;2;165;255;195:*CMakeLists.txt=0;38;2;165;255;195:*.gitattributes=0;38;2;165;255;195:*LICENSE-APACHE=0;38;2;153;153;153:*CMakeCache.txt=0;38;2;102;102;102:*CONTRIBUTORS.md=0;38;2;40;42;54;48;2;243;249;157:*.sconsign.dblite=0;38;2;102;102;102:*requirements.txt=0;38;2;165;255;195:*CONTRIBUTORS.txt=0;38;2;40;42;54;48;2;243;249;157:*package-lock.json=0;38;2;102;102;102:*.CFUserTextEncoding=0;38;2;102;102;102'
  export TERM="${TERM:-xterm-256color}"
  if [ "$TERM_PROGRAM" = "ghostty" ]; then
    if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
      source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
    fi
    export SNACKS_GHOSTTY=true
  fi
  export SHELL="$(which zsh)"
# }

# LESS {
  # https://linuxize.com/post/less-command-in-linux/
  export LESS='-RF'
  export LESS_HOME=$XDG_CONFIG_HOME/less
  export LESS_CACHE_HOME=$XDG_CACHE_HOME/less
  export LESSKEY=$LESS_CACHE_HOME/keys
  export LESSHISTFILE=$XDG_CACHE_HOME/history/lesshist
  export LESS_ADVANCED_PREPROCESSOR=1
# }

# [N]VIM {
  # +BundleInstall +qall, Install all vim bundles
  # https://superuser.com/a/874924/389767
  if _has_command nvim; then
    export EDITOR=$(command -v nvim)
    export VIM_PATH=$XDG_CONFIG_HOME/nvim
    export MYVIMRC=$VIM_PATH/init.lua
    export NVIM_LOG_FILE=$XDG_CACHE_HOME/nvim/.nvimlog
    alias vim=nvim
    alias vi=nvim
  else
    export EDITOR=$(command -v vim || command -v vi)
    alias vi=vim
  fi
# }

# EDITOR {
  export VISUAL=$EDITOR
  export SUDO_EDITOR=$EDITOR
  export GIT_EDITOR="$EDITOR -c 'startinsert'"
  export LAUNCH_EDITOR=$EDITOR
# }

if _has_command starship; then
  # STARSHIP | The minimal, blazing-fast, and infinitely customizable prompt for any shell!
  # https://starship.rs/config/#configuration
  export STARSHIP_CONFIG_HOME=$XDG_CONFIG_HOME/starship
  export STARSHIP_CONFIG=$STARSHIP_CONFIG_HOME/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship
fi

if _has_command gpg; then
  # GNUPG | The GNU Privacy Guard
  # https://gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
  # needed for git PGP-signed commits also needed for sops
  export GPG_TTY=$(tty)
  export GNUPGHOME=$XDG_CONFIG_HOME/gnupg
fi

if _has_command gopass; then
  # GOPASS | The slightly more awesome standard unix password manager for teams
  # https://github.com/gopasspw/gopass/blob/master/docs/config.md
  export GOPASS_CONFIG_HOME=$XDG_CONFIG_HOME/gopass
  export GOPASS_CONFIG=$GOPASS_CONFIG_HOME/config
  export GOPASS_HOMEDIR=$HOME
  export PASSWORD_STORE_DIR=$XDG_DATA_HOME/gopass/password-store
  export PASSWORD_STORE_CLIP_TIME=45 #secs
  export PASSWORD_STORE_ENABLE_EXTENSIONS=true pass
fi

if _has_command jq; then
  # JQ | A lightweight and flexible command-line JSON processor
  # https://stedolan.github.io/jq/manual/#Advancedfeatures
  export JQ_COLORS='1;30:0;37:0;37:0;37:0;32:1;37:1;37'
fi

if _has_command wakatime-cli; then
  # WAKATIME | WakaTime command line interface
  # https://github.com/wakatime/wakatime#wakatime
  export WAKATIME_HOME=$XDG_CONFIG_HOME/wakatime
fi

if _has_command npm; then
  # NPM | Node Package Manager
  # https://docs.npmjs.com/cli/v7/commands/npm-config
  # https://docs.npmjs.com/cli/v7/configuring-npm/npmrc
  # `npm config list` => List all main npm settings
  # `npm config ls -l` => List all npm settings

  # Path to the personal npm configuration file
  # npm will read configuration from this file instead of the default location ($HOME/.npmrc)
  export npm_config_userconfig=$XDG_CONFIG_HOME/npm/npmrc

  # Path to npm's cache directory, which includes logs ($HOME/.npm)
  export npm_config_cache=$XDG_STATE_HOME/npm # $HOME/.local/state/npm

  # Set where global packages are installed when running `npm install -g [package]`.
  # Global binaries go to ${prefix}/bin and global packages to ${prefix}/lib/node_modules
  # export npm_config_prefix=${XDG_LOCAL_DIR}/npm

  # Opt out of update notifications https://npmjs.com/package/update-notifier#user-settings
  export NO_UPDATE_NOTIFIER=1

  # NODE REPL
  # https://nodejs.org/api/repl.html#repl_environment_variable_options
  export NODE_NO_WARNINGS=1 # silence all process warnings
fi

if _has_command pnpm; then
  # PNPM | Fast, disk space efficient package manager
  # https://pnpm.io
  export PNPM_HOME=$XDG_DATA_HOME/pnpm # $HOME/.local/share/pnpm
fi

if _has_command gitlint; then
  # GITLINT | Path where gitlint looks for a config file
  # https://jorisroovers.com/gitlint/user_defined_rules
  export GITLINT_CONFIG=$XDG_CONFIG_HOME/gitlint/gitlint.cfg
fi

if _has_command luajit; then
  # LUA | Lua is a powerful, efficient, lightweight, embeddable scripting language
  # https://lua.org/manual/5.1/manual.html#5.4
  # https://nift.dev/docs/lua.html
  # 💡 luajit -e 'print(package.path)' luajit -e 'print(package.cpath)'
  export LUA_PATH="./?.lua;$HOMEBREW_SHARE/luajit-2.1/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/init.lua;$HOMEBREW_SHARE/lua/5.1/?.lua;/$HOMEBREW_SHARE/lua/5.1/?/init.lua"
  export LUA_CPATH="./?.so;/usr/local/lib/lua/5.1/?.so;/opt/homebrew/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so"
fi

if _has_command glow; then
  # GLOW | A terminal-based markdown reader, renderer, and formatter
  # https://charm.sh/docs/glow
  export GLOW_CONFIG_PATH=$XDG_CONFIG_HOME/glow/conf.yml
fi

if _has_command bat; then
  # BAT | A cat(1) clone with wings
  # https://github.com/sharkdp/bat#configuration-file
  export BAT_CONFIG_HOME=$XDG_CONFIG_HOME/bat
  export BAT_CONFIG_PATH=$BAT_CONFIG_HOME/bat.conf
fi

if _has_command rg; then
  # RIPGREP | A utility that combines the usability of The Silver Searcher with the raw speed of grep
  # https://github.com/BurntSushi/ripgrep
  export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/.ripgreprc
fi