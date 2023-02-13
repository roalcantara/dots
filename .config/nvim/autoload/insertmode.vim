"  Mimic Vim's 'insertmode':
"  https://neovim.io/doc/user/vim_diff.html#'insertmode'
autocmd BufWinEnter * startinsert
inoremap <Esc> <C-X><C-Z><C-]>
inoremap <C-C> <C-X><C-Z>
inoremap <C-L> <C-X><C-Z><C-]><Esc>
inoremap <C-Z> <C-X><C-Z><Cmd>suspend<CR>
noremap <C-C> <Esc>
snoremap <C-C> <Esc>
noremap <C-\><C-G> <C-\><C-N><Cmd>startinsert<CR>
cnoremap <C-\><C-G> <C-\><C-N><Cmd>startinsert<CR>
inoremap <C-\><C-G> <C-X><C-Z>
autocmd CmdWinEnter * noremap <buffer> <C-C> <C-C>
autocmd CmdWinEnter * inoremap <buffer> <C-C> <C-C>

lua << EOF
  vim.on_key(function(c)
    if c == '\27' then
      local mode = vim.api.nvim_get_mode().mode
      if mode:find('^[nvV\22sS\19]') and vim.fn.getcmdtype() == '' then
        vim.schedule(function()
          vim.cmd('startinsert')
        end)
      end
    end
  end)
EOF
