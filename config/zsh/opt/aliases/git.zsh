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
alias gb='g branches'
alias gbs='g show-branch'
alias gbv='g branch -vv'
alias gbva='g branches'
alias gbd='g branch --delete'
alias gbd!='g branch --delete --force'
alias gbx='g fzbd'  # (fuzzy) git branch -d [<branch>]
alias gbx!='g fzbx' # (fuzzy) git branch -D [<branch>]

# PULL
alias gfr='g pull --rebase'
alias gfra='g pull --rebase --autostash'
alias gprm='g pull --rebase --autostash $(git main-branch)'
alias gprd='g pull --rebase --autostash develop'

# CHECKOUT
# alias gco='g fzc' # (fuzzy) git checkout --guess [<pathspec>…​]
gco() {
  if [ $# -eq 0 ]; then
    # (fuzzy) git checkout --guess [<pathspec>…​]
    git fzc
  else
    git checkout -b "$@"
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
alias gs='g stash'

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
alias gpf='g push -v --force'
alias gpu='g push -v --set-upstream origin "$(git current-branch)"'
alias gpT='g push --tags'

# REMOTE
alias gR='g remote'
alias gRa='g remote add'

# TAGS
alias gtg='g tag --format "%(color:green bold)%(objectname:short)%09%(color:yellow bold)(%(refname:short))%(color:reset) %(color:white bold)%(contents:subject) %(color:reset)%(color:cyan)(%(authordate:format:%h/%d)) %(color:blue)%(authorname)" --sort -version:refname'

# Copy co-authors' names to clipboard
# https://blog.testdouble.com/posts/2020-04-07-favorite-things/
alias gcauth='g Co-authored-by: %s" "$(git log --pretty=format:"%an <%ae>" -1000 | sort | uniq | fzf)" | pbcopy'

# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# A distributed version control system
# https://git-scm.com/
alias -g d='/usr/bin/git --git-dir=$HOME/.dots/ --work-tree=$HOME'

# STATUS
alias dst='d status'
alias dsts='d status --short'

# BRANCH
alias db='d branch'
alias dbs='d show-branch'
alias dbv='d branch -vv'
alias dbva='d branches'
alias dbd='d branch --delete'
alias dbd!='d branch --delete --force'
alias dbx='d fzbd'  # (fuzzy) git branch -d [<branch>]
alias dbx!='d fzbx' # (fuzzy) git branch -D [<branch>]

# PULL
alias dfr='d pull --rebase'
alias dfra='d pull --rebase --autostash'

# CHECKOUT
alias dco='d fzc' # (fuzzy) git checkout --guess [<pathspec>…​]
alias dcoo='d checkout -b'
alias dcom='d checkout $(d main-branch)'
alias dco!='d fetch --all && d remote prune origin && d fzc'
alias dcom!='d fetch --all && d remote prune origin && d checkout $(d main-branch)'

# LOG
alias dl='d l'
alias dlo='d fzl | pbcopy' # (fuzzy) git log | pbcopy
alias dlol='d lol'         # git log long

# ADD
da() { # (fuzzy) git add --force [<pathspec>…​]
  [ -n "$1" ] && d add "$@" || d fza
}
alias daa='d add'
alias daaa='d add .'
alias ds='d stash'

# RESTORE
alias drs='d fzu'   # (fuzzy) git restore [<pathspec>…​] to discard changes in working directory
alias drss='d fzus' # (fuzzy) git restore --staged [<pathspec>…​] to unstage
alias drs!='d restore .'
alias drss!='d restore --staged .'
grm() { # (fuzzy) git rm --cached <file>
  [ -n "$1" ] && d rm -r --cached "$1" || d fzunstage
}

# COMMIT
alias dc='d commit --verbose'
alias dca='d commit --verbose --amend'
alias dcan='d commit --verbose --amend --no-verify'
alias dcane='d commit --verbose --amend --no-edit'
alias dcaa='d commit --verbose --amend --no-verify --no-edit'
alias dcw='d wip'
alias dct='d tmp'

# RESET
alias drh='d fzhs' # (fuzzy) git reset --soft [<pathspec>…​]
alias drH='d fzhh' # (fuzzy) git reset --hard [<pathspec>…​]
alias drH!='d update-ref -d HEAD'

# REBASE
alias dr='d fzr'    # (fuzzy) git rebase -i <commit>^
alias drw='d fzw'   # (fuzzy) git reword <commit>
alias de='d fze'    # (fuzzy) git edit <commit>
alias dd='d fzdiff' # (fuzzy) git diff [<commit>] [--] [<path>...]
alias dx='d fzd'    # (fuzzy) git drop <commit>
alias dff='d fzf'   # (fuzzy) git fix <commit>
alias drcc='d rebase --continue'
alias drsk='d rebase --skip'
alias dra='d rebase --abort'
alias dr!='d rebase -i --root'

# CHERRY-PICK
alias dcp='d cherry-pick --ff'
alias dcpc='d cherry-pick --continue'
alias dcpa='d cherry-pick --abort'

# PUSH
alias dp='d push -v'
alias dpf='d push -v --force'
alias dpu='d push -v --set-upstream origin "$(d current-branch)"'
alias dpT='d push --tags'

# REMOTE
alias dR='d remote'
alias dRa='d remote add'

# TAGS
alias dtg='d tag --format "%(color:green bold)%(objectname:short)%09%(color:yellow bold)(%(refname:short))%(color:reset) %(color:white bold)%(contents:subject) %(color:reset)%(color:cyan)(%(authordate:format:%h/%d)) %(color:blue)%(authorname)" --sort -version:refname'

# Copy co-authors' names to clipboard
# https://blog.testdouble.com/posts/2020-04-07-favorite-things/
alias dcauth='d Co-authored-by: %s" "$(d log --pretty=format:"%an <%ae>" -1000 | sort | uniq | fzf)" | pbcopy'

# For a bare repository setup, you'll need to specify both the git directory and work tree when using transcrypt
# https://github.com/agnivade/transcrypt
alias dt='GIT_ATTRIBUTES="$HOME/.config/.gitattributes" GIT_DIR="$HOME/.dots" GIT_WORK_TREE="$HOME" transcrypt'
