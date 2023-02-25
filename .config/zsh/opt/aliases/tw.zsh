# TASK WARRIOR ALIASES {
if (( $+commands[task] )); then
  alias tws='task'
  alias twa='tws add'
  alias twe='tws modify'
  alias twc='tws completed'
  alias twp='tws projects'
  alias twt='tws project:tecban'
  alias twd='tws projec:dots'
  alias twc='tws context list'
  alias twn='tws context none'
  alias twi='tws context isolutions'
  alias twh='tws context home'
  alias tww='tws context work'
  alias twr='tws reports'
  alias tl='tldr --list | fzf --ansi | xargs tldr'
fi
# }
