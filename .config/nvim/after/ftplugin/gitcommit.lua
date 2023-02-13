-- https://waylonwalker.com/til/neovim-config-for-git/
-- https://csswizardry.com/2017/03/configuring-git-and-vim/
vim.cmd[[
  autocmd FileType gitcommit call setpos('.', [0, 1, 1, 0])
  autocmd FileType gitcommit setlocal nocindent
  autocmd FileType gitcommit set textwidth=72
  set colorcolumn=+1
  autocmd FileType gitcommit set colorcolumn+=51
  autocmd FileType gitcommit,gitrebase,gitconfig set bufhidden=delete
]]
