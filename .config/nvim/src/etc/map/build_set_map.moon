---@param bufnr string | number | nil
---@return function
build_set_map = (bufnr)-> (...)-> vim.api.nvim_buf_set_keymap(bufnr, ...)

return build_set_map
