local set_buf_keymap
set_buf_keymap = function(bufnr, mode, lhs, rhs, args)
  return vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, args)
end
local set_bmap
set_bmap = function(bufnr, lhs, rhs)
  return set_buf_keymap(bufnr, 'n', lhs, rhs, {
    noremap = true,
    silent = false
  })
end
return {
  set_buf_keymap = set_buf_keymap,
  set_bmap = set_bmap
}
