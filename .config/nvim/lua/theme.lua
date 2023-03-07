return vim.cmd([[	" disable Background Color Erase (BCE) for better performance
	if &term =~ '256color'
		set t_ut=
	endif

	augroup settings
		autocmd!
		autocmd TextYankPost * lua vim.highlight.on_yank{timeout=150}
	augroup END

  highlight! WhichKeyFloat guibg=#808080
  syntax on
  filetype plugin on
]])
