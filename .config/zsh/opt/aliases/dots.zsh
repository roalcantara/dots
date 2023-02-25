# ALIASES
# http://zsh.sourceforge.net/Intro/intro_8.html

# A distributed version control system
# https://git-scm.com/
alias -g d='/usr/bin/git --git-dir=$HOME/.git/ --work-tree=$HOME'

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
alias dbx='d fzbd'              # (fuzzy) git branch -d [<branch>]
alias dbx!='d fzbx'             # (fuzzy) git branch -D [<branch>]

# PULL
alias dfr='d pull --rebase'
alias dfra='d pull --rebase --autostash'

# CHECKOUT
alias dco='d fzc'               # (fuzzy) git checkout --guess [<pathspec>…​]
alias dcoo='d checkout -b'
alias dcom='d checkout $(d main-branch)'
alias dco!='d fetch --all && d remote prune origin && d fzc'
alias dcom!='d fetch --all && d remote prune origin && d checkout $(d main-branch)'

# LOG
alias dl='d l'
alias dlo='d fzl | pbcopy'      # (fuzzy) git log | pbcopy
alias dlol='d lol'              # git log long

# ADD
da() {                          # (fuzzy) git add --force [<pathspec>…​]
  [ -n "$1" ] && d add "$@" || d fza
}
alias daa='d add'
alias daaa='d add .'
alias ds='d stash'

# RESTORE
alias drs='d fzu'                 # (fuzzy) git restore [<pathspec>…​] to discard changes in working directory
alias drss='d fzus'               # (fuzzy) git restore --staged [<pathspec>…​] to unstage
alias drs!='d restore .'
alias drss!='d restore --staged .'
grm() {                         # (fuzzy) git rm --cached <file>
  [ -n "$1" ] && d rm -r --cached "$1" || d fzunstage
}

# COMMIT
alias dc='d commit --verbose'
alias dca='d commit --verbose --amend'
alias dcan='d commit --verbose --amend --no-verify'
alias dcane='d commit --verbose --amend --no-edit'
alias dcann='d commit --verbose --amend --no-verify --no-edit'
alias dcw='d wip'
alias dct='d tmp'

# RESET
alias drh='d fzhs'              # (fuzzy) git reset --soft [<pathspec>…​]
alias drH='d fzhh'              # (fuzzy) git reset --hard [<pathspec>…​]
alias drH!='d update-ref -d HEAD'

# REBASE
alias dr='d fzr'                # (fuzzy) git rebase -i <commit>^
alias drw='d fzw'               # (fuzzy) git reword <commit>
alias de='d fze'                # (fuzzy) git edit <commit>
alias dd='d fzdiff'             # (fuzzy) git diff [<commit>] [--] [<path>...]
alias dx='d fzd'                # (fuzzy) git drop <commit>
alias dff='d fzf'               # (fuzzy) git fix <commit>
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
alias dpp='d push -v --force'
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
