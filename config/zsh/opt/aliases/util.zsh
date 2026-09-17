# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html
alias grc='noglob grc'

# GitHub Copilot
# Use Copilot with the GitHub CLI to get suggestions and explanations for the command line
# https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line
if (( $+commands[gh] )); then
  # GitHub Copilot
  alias ghcp='gh copilot'
  # Explain a command
  alias cpe='ghcp explain'
  # Suggest a command
  alias cps='ghcp suggest'
fi

# https://phoenixnap.com/kb/diff-color
alias diff='diff --color -u'

# Grep history
alias hgrep='fc -Dlim "*$@*" 1'

# HTOP
# Improved top (interactive process viewer)
# https://htop.dev
if (( $+commands[htop] )); then
  alias top!=$(which top)
  alias top=htop
fi

# BAT
# A cat(1) clone with wings
# https://github.com/sharkdp/bat#configuration-file
if (( $+commands[bat] )); then
  export BAT_PAGER="${PAGER}"
  alias cat!='$(which cat)'
  alias cat=bat
fi

# Read system manual pages (man) using bat as the manual page formatter.
# https://github.com/eth-p/bat-extras/blob/master/doc/batman.md
if (( $+commands[batman] )); then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias man!=$(which man)
  alias man=batman
fi

# Open-source code editor
# https://code.visualstudio.com/insiders
if (( $+commands[code-insiders] )); then
  alias codei=code-insiders
fi

# Aerospace
# https://github.com/aerospace-dev/aerospace
# https://github.com/omerxx/dotfiles/blob/c52df4021f55fd5529ae7f2548996287252b4f43/nushell/config.nu#L907
if (( $+commands[aerospace] )); then
  # List all opened windows and pick one on ENTER
  alias ww="aerospace list-windows --all | fzf --bind 'enter:execute(bash -c \"aerospace focus --window-id {1}\")+abort'"
fi

# Fabric
# https://github.com/fabric-ai/fabric
# https://github.com/danielmiessler/fabric?tab=readme-ov-file#using-package-managers
if (( $+commands[fabric-ai] )); then
  # As Homebrew or the Arch Linux package managers makes fabric available as fabric-ai
  alias fabric="fabric-ai"
fi

# ZOXIDE
# A smarter cd command
# https://github.com/ajeetdsouza/zoxide
# https://youtu.be/-2Nz8rn05bk
if (( $+commands[zoxide] )); then
  # zim-zoxide initialises zoxide with `--cmd cd`, so zoxide already defines
  # cd() and cdi() directly. Aliasing cd->z would shadow those functions with
  # a command that does not exist under this init mode.
  alias 'cd!'='builtin cd'   # escape hatch to the real builtin
fi
