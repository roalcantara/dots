-- Support for vim for LuaFormatter.
-- https://github.com/andrejlevkovitch/vim-lua-format
vim.cmd[[autocmd FileType lua nnoremap <buffer> <c-k> :call LuaFormat()<cr>]]
vim.cmd[[autocmd BufWrite *.lua call LuaFormat()]]
