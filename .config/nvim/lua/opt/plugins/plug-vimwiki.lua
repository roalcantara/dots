vim.g.vimwiki_list = {
  {
    path = '~/.config/nvim/wiki',
    syntax = 'markdown',
    ext = '.md'
  }
}
vim.g.vimwiki_ext2syntax = {
  ['.md'] = 'markdown',
  ['.markdown'] = 'markdown',
  ['.mdown'] = 'markdown'
}
vim.g.vimwiki_markdown_link_ext = 1
vim.g.markdown_folding = 1
