local sources_by_filetype = {
  default = { 'lsp', 'snippets', 'avante', 'copilot', 'buffer', 'path' },
  lua = { 'lazydev', 'lsp', 'snippets', 'avante', 'copilot', 'buffer', 'path' },
  gitcommit = { 'git', 'conventional_commits', 'snippets', 'avante', 'copilot', 'lsp', 'buffer', 'path' },
  sql = { 'lsp', 'snippets', 'avante', 'copilot', 'buffer', 'path', 'dadbod' },
  comments = { 'buffer', 'snippets', 'avante', 'copilot' }
}

local get_filetype = function()
  local success, node = pcall(vim.treesitter.get_node)
  if success and node and vim.tbl_contains({ 'comment', 'line_comment', 'block_comment' }, node:type()) then
    return 'comments'
  end
  return vim.bo.filetype
end

--- Returns the default sources by filetype
---@return table
local function get_default_sources()
  return sources_by_filetype[get_filetype()] or sources_by_filetype.default
end

return get_default_sources
