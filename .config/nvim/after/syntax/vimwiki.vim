" TaskWiki - Proper project management with Taskwarrior in vim
" https://github.com/tools-life/taskwiki
" https://youtu.be/UuHJloiDErM
syntax match todoCheckbox '\v.*\[\ \]'hs=e-2 conceal cchar=
syntax match todoCheckbox '\v.*\[X\]'hs=e-2 conceal cchar=
setlocal conceallevel=2
hi Conceal guibg=NONE
" hi clear Conceal
