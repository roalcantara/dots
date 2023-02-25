# FZF-TAB
# https://github.com/Aloxaf/fzf-tab/wiki/Configuration
# disable sort when completing options of any command
zstyle ':completion:complete:*:options' sort false

zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:*' show-group full
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'
# / trigger continuous completion (useful when completing a deep path)
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' query-string prefix input first
# execute a command right after pressing enter for fzf-tab
zstyle ':fzf-tab:*' fzf-bindings 'tab:accept'
zstyle ':fzf-tab:*' accept-line enter

zstyle ':fzf-tab:*:' prefix '·'                                                                                                                    # If not set zstyle ':completion:*:descriptions' format, it will be set to empty
zstyle ':fzf-tab:*:' fzf-pad 4                                                                                                                     # How many lines does fzf's prompt occupied
zstyle ':fzf-tab:complete:cd:*' tag-order local-directories named-directories                                                                      # preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:(cd|ls):*' fzf-preview 'exa -1 --color=always --icons --git --classify --sort=.name --group-directories-first $realpath' # remember to use single quote here!!!

# environment variables
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-preview 'command -v $word 2>/dev/null || eval echo \$$word'
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' fzf-flags --tac --no-sort --height=30% --preview-window down,30%,wrap

# git
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-help:*' fzf-preview 'git help $word | bat -plman --color=always'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
	'case "$group" in
	"commit tag") git show --color=always $word ;;
	*) git show --color=always $word | delta ;;
	esac'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
	'case "$group" in
	"modified file") git diff $word | delta ;;
	"recent commit object name") git show --color=always $word | delta ;;
	*) git log --color=always $word ;;
	esac'

# man
zstyle ':fzf-tab:complete:(\\|)run-help:*' fzf-preview 'run-help $word'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'

# [kill/ps] give a preview of commandline arguments when completing `kill`
# https://github.com/Aloxaf/fzf-tab/wiki/Preview
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# show systemd unit status
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
