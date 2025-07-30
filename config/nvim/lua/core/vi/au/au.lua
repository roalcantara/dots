local aug = require('core/vi/au/aug')

--- Wrapper for vim.api.nvim_create_autocmd which clears the autocmds for the buffer if a group_name is provided
--- @param event string|table Event(s) name(s)
--- @param opts table { group? = number|string, buffer? = number, callback? = function, desc? = string, clear_autocmds? = boolean,  }
--- @return number Autocmd ID
--- @return number? Group ID if a group is created
local function au(event, opts)
  opts = opts or {}

  if opts.group and type(opts.group) == 'string' then
    opts.group = aug(tostring(opts.group))
  end

  if opts.clear_autocmds and opts.group then
    vim.api.nvim_clear_autocmds({ buffer = opts.buffer, group = opts.group })

    return vim.api.nvim_create_autocmd(event, opts), opts.group
  end

  return vim.api.nvim_create_autocmd(event, opts)
end

return au
