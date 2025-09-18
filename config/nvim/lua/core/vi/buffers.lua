-- Buffer and editor utilities
local M = {}

--- Get valid buffers
--- @param ft_autoclose string[]
--- @return table[] valid_buffers
function M.get_valid_buffers(ft_autoclose)
  return vim.tbl_filter(function(buf)
    if not vim.api.nvim_buf_is_loaded(buf) then
      return false
    end

    local filetype = vim.api.nvim_get_option_value('filetype', { buf = buf })
    local buftype = vim.api.nvim_get_option_value('buftype', { buf = buf })
    local listed = vim.api.nvim_get_option_value('buflisted', { buf = buf })

    return listed and buftype == '' and not vim.tbl_contains(ft_autoclose, filetype)
  end, vim.api.nvim_list_bufs())
end

--- Lists Neovim sorted filetypes
--- @return string[] Filetypes sorted alphabetically
function M.get_filetypes()
  local values = {}
  for _, path in ipairs(vim.api.nvim_get_runtime_file('ftplugin/*', true)) do
    local ft = vim.fn.fnamemodify(path, ':t:r')
    values[ft] = true
  end

  local sorted_filetypes = vim.tbl_keys(values)
  table.sort(sorted_filetypes)

  return sorted_filetypes
end

return M
