local M = {}

function M.is_headless()
  return #vim.api.nvim_list_uis() == 0
end

function M.is_win()
  return vim.loop.os_uname():match 'Windows'
end

function M.is_mac()
  return vim.loop.os_uname():match 'Darwin'
end

return M
