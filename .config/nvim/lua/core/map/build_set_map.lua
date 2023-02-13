local build_set_map
build_set_map = function(bufnr)
  return function(...)
    return vim.api.nvim_buf_set_keymap(bufnr, ...)
  end
end
return build_set_map
