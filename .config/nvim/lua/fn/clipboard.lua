local M = {}
function M.clipboard()
  if vim.loop.os_uname().sysname == 'Darwin' then
    return {
      cache_enabled = 0,
      name = 'macOS-clipboard',
      copy = {
        ['+'] = 'pbcopy',
        ['*'] = 'pbcopy',
      },
      paste = {
        ['+'] = 'pbpaste',
        ['*'] = 'pbpaste',
      },
    }
  end
  return 'unnamedplus'
end
return M
