# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# A distributed version control system
# https://git-scm.com/
alias -g g=git

# STATUS
alias gst='g status'
alias gsts='g status --short'

# BRANCH
alias gb!='g branch'
alias gbs='g branches'
alias gba='g show-branch'
alias gbv='g branch -vv'
alias gbb='g fzb'  # (fuzzy) git branch -d [<branch>] / -D [<branch>]

# PULL
alias gfr='g pull --rebase'
alias gfra='g pull --rebase --autostash'
alias gprm='g pull --rebase --autostash $(git main-branch)'
alias gprd='g pull --rebase --autostash develop'

# CHECKOUT
# alias gco='g fzb' # (fuzzy) git checkout --guess [<pathspec>…​]
gco() {
  if [ $# -eq 0 ]; then
    # (fuzzy) git checkout --guess [<pathspec>…​]
    git fzb
  else
    git checkout "$@"
  fi
}
alias gco!='g fetch --all && git remote prune origin && git fzc'
alias gcom='g checkout $(git main-branch)'
alias gcod='g checkout develop'
alias gcom!='g fetch --all && git remote prune origin && git checkout $(git main-branch)'

# LOG
alias gl='g l'
alias glo='g fzl | pbcopy' # (fuzzy) git log | pbcopy
alias glol='g lol'         # git log long

# ADD
ga() {
  if [ $# -eq 0 ]; then
    # (fuzzy) git add --force [<pathspec>…​]
    git fza
  else
    git add "$@"
  fi
}
alias gaa='g add .'
alias gss='g stash'

# RESTORE
alias grs='g fzu'   # (fuzzy) git restore [<pathspec>…​]
alias grss='g fzus' # (fuzzy) git restore --staged [<pathspec>…​]
alias grs!='g restore .'
alias grss!='g restore --staged .'
grm() {
  [ -n "$1" ] && git rm -r --cached "$1" || git fzunstage # (fuzzy) git rm --cached <file>
}

# COMMIT
alias gc='g commit --verbose'
alias gca='g commit --verbose --amend'
alias gcan='g commit --verbose --amend --no-verify'
alias gcane='g commit --verbose --amend --no-edit'
alias gcaa='g commit --verbose --amend --no-verify --no-edit'
alias gcw='g wip'
alias gct='g tmp'

# RESET
alias grh='g fzhs' # (fuzzy) git reset --soft [<pathspec>…​]
alias grH='g fzhh' # (fuzzy) git reset --hard [<pathspec>…​]
alias grH!='g update-ref -d HEAD'

# REBASE
alias gr='g fzr'    # (fuzzy) git rebase -i <commit>^
alias grw='g fzw'   # (fuzzy) git reword <commit>
alias ge='g fze'    # (fuzzy) git edit <commit>
alias gd='g fzdiff' # (fuzzy) git diff [<commit>] [--] [<path>...]
alias gx='g fzd'    # (fuzzy) git drop <commit>
alias gff='g fzf'   # (fuzzy) git fix <commit>
alias grcc='g rebase --continue'
alias grsk='g rebase --skip'
alias gra='g rebase --abort'
alias gr!='g rebase -i --root'

# CHERRY-PICK
alias gcp='g cherry-pick --ff'
alias gcpc='g cherry-pick --continue'
alias gcpa='g cherry-pick --abort'

# PUSH
alias gp='g push -v'
alias gpf='g pf'
alias gpu='g pc'
alias gpT='g push --tags'

# REMOTE
alias gR='g remote'
alias gRa='g remote add'

# TAGS
alias gtg='g tag --format "%(color:green bold)%(objectname:short)%09%(color:yellow bold)(%(refname:short))%(color:reset) %(color:white bold)%(contents:subject) %(color:reset)%(color:cyan)(%(authordate:format:%h/%d)) %(color:blue)%(authorname)" --sort -version:refname'

# Copy co-authors' names to clipboard
# https://blog.testdouble.com/posts/2020-04-07-favorite-things/
alias gcauth='printf "Co-authored-by: %s\n" "$(git log --pretty=format:"%an <%ae>" -1000 | sort -u | fzf)" | pbcopy'