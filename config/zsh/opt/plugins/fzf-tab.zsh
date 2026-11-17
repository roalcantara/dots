#!/usr/bin/env zsh

# Tab completion using fzf
# This is distinct from fzf's own implementation for completion, in that it works with the existing completion mechanisms rather than creating a new mechanism.
# https://github.com/lincheney/fzf-tab-completion
# https://zimfw.sh/docs/cheatsheet/#tab-completionhttps://zimfw.sh/docs/cheatsheet/#tab-completion


## INSTALLATIONS
# `brew install zsh zsh-completions fzf`

## CONFIGURATIONS

### ZSH

# https://github.com/lincheney/fzf-tab-completion?tab=readme-ov-file#zsh
# Note that this does not provide **-style triggers, you will need to enable fzf's zsh completion as well.
export FZF_COMPLETION_TRIGGER='**'

# Use eza for the FZF directory listing
# https://github.com/lincheney/fzf-tab-completion?tab=readme-ov-file#zsh
# https://github.com/lincheney/fzf-tab-completion?tab=readme-ov-file#installation
export FZF_DEFAULT_COMMAND='eza --color=always --classify --group-directories-first --long --icons -a'
export FZF_DEFAULT_OPTS="
      --cycle
      --ansi
      --inline-info
      --keep-right
      --marker '✔'
      --pointer '▶'
      --margin 1,1
      --color dark
      $FZF_THEME_OPTS
      --prompt '❯ '
      --height=40%
      --tiebreak 'chunk'
      --bind 'tab:down,btab:up'"

# - [CTRL-T] $($FZF_CTRL_T_COMMAND) to get a list of files and directories and paste them onto the command-line
#  Preview file with bat (https://github.com/sharkdp/bat)
#  [CTRL /] Change preview window position
#  [CTRL Y] Copy command into clipboard
#  [CTRL E] Edit command in $EDITOR
export FZF_CTRL_T_COMMAND="fd
      --type file
      --ignore-case
      --color=always
      --hidden
      --follow
      --exclude .git"
export FZF_CTRL_T_OPTS="
      --walker-skip .git,node_modules,target
      --color header:bold
      --select-1 --exit-0 --marker ⇒
      --prompt 'Pick File or Directory ❯'
      --header '[^ y] copy command into clipboard'
      --bind 'tab:down,btab:up'
      --bind 'ctrl-/:change-preview-window(down|hidden|)'
      --bind 'ctrl-e:execute(echo {+} | xargs -o '${EDITOR}' -)+abort'
      --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'"

# ALT-C	  cd into the selected directory
#     Print tree structure in the preview window
#     CTRL+Y  => copy path into clipboard
# https://github.com/junegunn/fzf?tab=readme-ov-file#fuzzy-completion-for-bash-and-zsh
# https://github.com/junegunn/fzf?tab=readme-ov-file#settings
export FZF_ALT_C_COMMAND='eza --color=always --classify --group-directories-first --long --icons -a'
export FZF_ALT_C_OPTS="
      --walker-skip .git,node_modules,target
      --color header:bold
      --select-1 --exit-0
      --prompt 'CD Directory ❯'
      --bind 'tab:down,btab:up'
      --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
      --preview 'eza --color=always --classify --group-directories-first --binary --long --icons --header --modified --time-style=iso -a --git {}''
      --header '[^ Y] copy path into clipboard'"

# CTRL-R	  Paste the selected command from history into the command line
# https://github.com/junegunn/fzf?tab=readme-ov-file#fuzzy-completion-for-bash-and-zsh
# https://github.com/junegunn/fzf?tab=readme-ov-file#settings
# export FZF_CTRL_R_OPTS="
#       --prompt 'Selected command from history ❯ '
#       --header '[^ y] copy command into clipboard'
#       --preview '(highlight -O ansi -l {} 2> /dev/null || bat --color=always --line-range :50 {} 2> /dev/null || cat {} || tree -C {}) 2> /dev/null | head -200'
#       --bind 'tab:down,btab:up'
#       --bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'"

# FZF_TAB
# https://github.com/Aloxaf/fzf-tab
# https://github.com/Aloxaf/fzf-tab/wiki/Configuration
# c-x h -> get context of the completion
zstyle -d ':completion:*' format

# Group headers ([commands], [options]…) and one theme colour per group, from the active theme's
# DOTS_FZF_TAB_GROUP_COLORS; `,` and `.` switch groups. fzf-tab colours a whole candidate line per group, never the
# description alone (it ignores pattern list-colors).
zstyle ':fzf-tab:*' show-group full
if (( ${#DOTS_FZF_TAB_GROUP_COLORS} )); then
  zstyle ':fzf-tab:*' group-colors "${DOTS_FZF_TAB_GROUP_COLORS[@]}"
else
  zstyle ':fzf-tab:*' group-colors \
    $'\e[38;2;189;147;249m' $'\e[38;2;139;233;253m' $'\e[38;2;80;250;123m' \
    $'\e[38;2;255;184;108m' $'\e[38;2;255;121;198m' $'\e[38;2;241;250;140m'
fi
zstyle ':fzf-tab:*' prefix ''

# Preview window settings
zstyle ':fzf-tab:*' fzf-command fzf
# It specifies the key to trigger a continuous completion (accept the result and start another completion immediately). It's useful when completing a long path.
zstyle ':fzf-tab:*' continuous-trigger 'tab'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' single-group color header
# It specifies the key to accept and run a suggestion in one keystroke.
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'
# Press enter to accept the completion
zstyle ':fzf-tab:*' accept-line enter
# Pressing this key will use the currently entered user input as the final completion output
zstyle ':fzf-tab:*' print-query alt-enter
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default, so it repeats the flags and takes its colours from
# the theme's FZF_THEME_OPTS. --style=full frames the list and the preview.
zstyle ':fzf-tab:*' fzf-flags --bind=right:accept --bind=enter:accept \
    --cycle \
    --ansi \
    --inline-info \
    --keep-right \
    --marker '✔' \
    --pointer '▶' \
    --prompt '❯ ' \
    --height=40% \
    --tiebreak='chunk' \
    --layout=reverse \
    --style=full \
    --list-label=' matches ' \
    --preview-label=' preview ' \
    ${(z)FZF_THEME_OPTS}

# Environment Variables completion configuration
zstyle ':fzf-tab:complete:*:*:*:*:variables' \
  fzf-preview 'bat --style=full --color=always --language=sh --line-range :500 <(echo ${(P)word}) 2>/dev/null || echo ${(P)word}'

# Preview for environment variables (https://github.com/Aloxaf/fzf-tab/wiki/Preview#environment-variable)
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'bat --style=full --color=always --language=sh --line-range :500 <(echo ${(P)word}) 2>/dev/null || echo ${(P)word}'

# Preview for man and run-help (https://github.com/Aloxaf/fzf-tab/wiki/Preview#other-tips)
# Set up bat for man page previews in fzf-tab
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'MANPAGER="sh -c \"col -bx | bat -l man -p --color=always\"" man ${word} 2>/dev/null || echo "No manual entry for ${word}"'
zstyle ':fzf-tab:complete:(\\|)run-help:*' fzf-preview 'MANPAGER="sh -c \"col -bx | bat -l man -p --color=always\"" run-help ${word} 2>/dev/null || echo "No help for ${word}"'

# Preview for systemctl (https://github.com/Aloxaf/fzf-tab/wiki/Preview#show-systemd-unit-status)
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Preview for brew (https://github.com/Aloxaf/fzf-tab/wiki/Preview#homebrew)
zstyle ':fzf-tab:complete:brew-(install|uninstall|search|info):*-argument-rest' fzf-preview '
  if [[ $word == -* ]]; then cmdhelp $word "${words[@]}"; else brew info $word; fi'

# Preview for todo: a task ID shows the task; anything else, the help (cmdhelp)
zstyle ':fzf-tab:complete:todo*:*' fzf-preview '
  out=$(todo list --tasks 2>/dev/null | awk -v w=" $word — " '\''index($0, w) { p=1 } p { if (p > 1 && /^ *\[/) exit; print; p++ }'\'')
  if [[ -n "$out" ]]; then
    printf "%s\n" "$out"
  else
    cmdhelp $word "${words[@]}"
  fi'

# tags in context :completion::complete:mise:: argument-rest  (_arguments _mise)
# tags in context :completion::complete:mise:argument-rest: argument-rest  (_arguments _mise)
# Preview for mise install command with tool information
# Run mise tool $word for tool details
zstyle ':fzf-tab:complete:mise:argument-rest' fzf-preview 'mise tool $word'

# GIT (https://github.com/Aloxaf/fzf-tab/wiki/Preview#git)
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git show --color=always $word | bat --color=always -l diff -p' # Preview for git log
# Show full path and diff preview
zstyle ':fzf-tab:complete:git-add:*' fzf-preview '
 file=${word#./}  # Remove ./ prefix if present
 if git ls-files --error-unmatch -- "$file" >/dev/null 2>&1; then
   git diff --color=always -- "$file"
 else
   git diff --color=always --no-index /dev/null "$file"
 fi'
# Preview for git restore --staged (unstaging)
zstyle ':fzf-tab:complete:*:git-restore:*:options' fzf-preview '
if [[ $group == "--staged" ]]; then
 git diff --cached --color=always $word
fi'
# Preview for git restore (discarding changes)
zstyle ':fzf-tab:complete:*:git-restore:*' fzf-preview '
if [[ $group != "--staged" ]]; then
 git diff --color=always $word
fi'
# Checkout with branch/remote preview
zstyle ':fzf-tab:complete:*:git-checkout:*' fzf-completion-opts '--preview-window=right:60%' fzf-preview '
branch=$word
if [[ $branch == -* ]]; then
 cmdhelp $word "${words[@]}"
elif [[ $branch == *//* ]]; then
 git log --color=always -n 50 --graph --pretty=format:"%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" $branch
else
 if git show-ref --verify --quiet refs/heads/$branch; then
   git log --color=always -n 50 --graph --pretty=format:"%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" $branch
 else
   git log --color=always -n 50 --graph --pretty=format:"%Cred%h%Creset - %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" origin/$branch
 fi
fi'

# One preview for a path, shared by the directory completions and the generic file branch: a directory lists as `la`
# lists it ($DOTS_LA_CMD, set in config/zsh/opt/aliases/ls.zsh), a text file shows in bat, anything else (images,
# binaries) shows what `file` says it is. Previews run in a child shell, so this is a string inlined into the
# zstyles, not a function. The command is word-split, never eval'd: a directory named `a$(cmd)` must not run cmd.
_dots_preview_path='
  if [[ -d $realpath ]]; then
    ${=DOTS_LA_CMD} "$realpath"
  elif [[ -f $realpath ]] && file -b --mime-type "$realpath" 2>/dev/null | grep -q "^text/"; then
    bat --style=numbers,changes --color=always --line-range :300 "$realpath" 2>/dev/null || file -b "$realpath"
  else
    file -b "$realpath"
  fi'

# Preview the directory's contents as `la` when completing eza, cd, z or __zoxide_z
# (https://github.com/Aloxaf/fzf-tab/wiki/Preview)
zstyle ':fzf-tab:complete:eza:*' fzf-preview "$_dots_preview_path"
zstyle ':fzf-tab:complete:cd:*' fzf-preview "$_dots_preview_path"
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview "$_dots_preview_path"
zstyle ':fzf-tab:complete:z:*' fzf-preview "$_dots_preview_path"

# Every other completion, least specific so the previews above win: a path shows through the shared helper; a
# subcommand or flag, its --help coloured by bat (config/bin/cmdhelp, which runs only subcommands the parent's help
# lists).
zstyle ':fzf-tab:complete:*' fzf-preview "
  if [[ -e \$realpath ]]; then
    $_dots_preview_path
  else
    cmdhelp \$word \"\${words[@]}\"
  fi"
