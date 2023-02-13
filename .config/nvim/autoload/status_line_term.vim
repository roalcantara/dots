"  Mimic Vim's StatusLineTerm:
"  https://neovim.io/doc/user/vim_diff.html#default-mappings
hi StatusLineTerm ctermfg=black ctermbg=green
hi StatusLineTermNC ctermfg=green
autocmd TermOpen,WinEnter * if &buftype=='terminal'
  \|setlocal winhighlight=StatusLine:StatusLineTerm,StatusLineNC:StatusLineTermNC
  \|else|setlocal winhighlight=|endif
