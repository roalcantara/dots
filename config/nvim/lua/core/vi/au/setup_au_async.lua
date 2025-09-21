local function debug(augroup_name, autocommand, created)
  local events
  if type(autocommand.event) == 'table' then
    events = table.concat(autocommand.event, '_')
  else
    events = autocommand.event
  end
  Neo.debug(('[%s/%s] created (%d) ✔'):format(augroup_name, events, created), { title = 'Autocmds' })
end

-- Creating autocommands
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommand-create
-- https://neovim.io/doc/user/lua-guide.html#lua-guide-autocommands-group
local function create_autocmds(options)
  local augroup = require('core/vi/au/aug')
  local created = 1
  --- @async
  local init_co = coroutine.create(function()
    for augroup_name, autocommands in pairs(options) do
      local group = augroup(augroup_name)
      for _, autocommand in ipairs(autocommands) do
        local opts = vim.tbl_deep_extend('force', autocommand.opts or {}, { group = group })
        vim.api.nvim_create_autocmd(autocommand.event, opts)
        debug(augroup_name, autocommand, created)
        created = created + 1
      end
    end
    coroutine.yield()
  end)

  local function resume_loading()
    if coroutine.status(init_co) ~= 'dead' then
      coroutine.resume(init_co)
      vim.defer_fn(resume_loading, 50)
    end
  end

  resume_loading()
end

-- Autocmds are automatically loaded on the VeryLazy event
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
return create_autocmds
