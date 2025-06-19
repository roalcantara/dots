
--- Get foldtext for Neovim < 0.10.0
--- @return string|nil foldtext - The fold text or nil if not found
local function foldtext()
  return vim.api.nvim_buf_get_lines(0, vim.v.lnum - 1, vim.v.lnum, false)[1]
end

return foldtext
