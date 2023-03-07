set_buf_keymap = (bufnr, mode, lhs, rhs, args)->
  vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, args)

set_bmap = (bufnr, lhs, rhs)->
  set_buf_keymap(bufnr, 'n', lhs, rhs, {noremap: true, silent: false})

return {
  :set_buf_keymap,
  :set_bmap
}
