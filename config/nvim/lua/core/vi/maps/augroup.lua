local PREFIX = "lazyvim_custom_"

--- Remove existing autocmds by their group name (which is prefixed with `lazyvim_custom_` for the defaults)
--- @param name string Name of the autocmd group
--- @param opts table? Options for the autocmd group
--- @return number Autocmd group ID
local function augroup(name, opts)
  return vim.api.nvim_create_augroup(PREFIX .. name, opts or { clear = true })
end

return augroup
