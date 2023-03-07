-- Personal Wiki for Vim
-- http://vimwiki.github.io
-- Proper project management with Taskwarrior in vim.
-- https://github.com/tools-life/taskwiki
-- require('core/api/var').set({
--   vimwiki_list = { path = '~/.config/nvim/wiki', syntax = 'narkdown', ext = 'md' },
--   vimwiki_ext2syntax = { ['.md'] = 'markdown', ['.markdown'] = 'markdown', ['.mdown'] = 'markdown' },
--   vimwiki_markdown_link_ext = 1, -- markdown links as [text](link)
--   taskwiki_markdown_syntax = 'markdown',
--   markdown_folding = 1
-- })
vim.g.vimwiki_list = {{path: '~/.config/nvim/wiki', syntax: 'markdown', ext: '.md'}}
vim.g.vimwiki_ext2syntax = {['.md']: 'markdown', ['.markdown']: 'markdown', ['.mdown']: 'markdown'}
vim.g.vimwiki_markdown_link_ext = 1 -- markdown links as [text](link)
-- vim.g.taskwiki_markdown_syntax = 'markdown'
vim.g.markdown_folding = 1

-- vim.cmd [[autocmd FileType vimwiki set ft=markdown]]
