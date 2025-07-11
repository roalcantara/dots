--- Lists Neovim soreted filetypes
---@return string[] Filetypes sorted alphabetically
return function()
  local values = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file("ftplugin/*", true)) do
    local ft = vim.fn.fnamemodify(path, ":t:r")
    values[ft] = true
  end

  local sorted_filetypes = vim.tbl_keys(values)
  table.sort(sorted_filetypes)

  return sorted_filetypes
end
