vim.cmd([[autocmd FileType lua nnoremap <buffer> <c-k> :call LuaFormat()<cr>]])
return vim.cmd([[autocmd BufWrite *.lua call LuaFormat()]])
