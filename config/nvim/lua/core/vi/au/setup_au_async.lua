-- Autocmds are automatically loaded on the VeryLazy event
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
local modules = {}
local h = {

  --- Get a module from the modules table or load it if it doesn't exist
  --- @param module_path string
  --- @return function|table|false module or false if failed to load
  get_module = function(module_path)
    if not modules[module_path] then
      local ok, module = pcall(require, module_path)
      if not ok then
        return false -- Early return on failure
      end
      modules[module_path] = module
    end
    return modules[module_path]
  end,
  get_command = function(module, action)
    if action and type(action) == 'function' then
      return function()
        return action(module)
      end
    end

    if type(module) == 'function' then
      return module
    end

    return module
  end,
}
-- local function create_single_user_command(info)
--   local name, module_path, opts, action = info.cmd, info.module.path, info.opts, info.action

--   local module = h.get_module(module_path)
--   if not module then
--     Snacks.notify.error('Failed to load module: ' .. module_path)
--     return false
--   end

--   local command = h.get_command(module, action)
--   if type(command) ~= 'function' and type(command) ~= 'string' then
--     Snacks.notify.error('Failed to load command: `' ..
--       name .. '`. Module is not a function or action is not defined!')
--     return false
--   end

--   return vim.api.nvim_create_user_command(name, command, opts or {})
-- end

h.load_modules = function(options)
  local mods = {}
  for mod_name, mod in pairs(options) do
    mods[mod_name] = h.get_module(mod.path)
  end
  return mods
end

local function setup_au_async(options)
  --- @async
  local init_co = coroutine.create(function()
    local mods = h.load_modules(options.modules)
    local augroup = mods.augroup
    local autocmd = mods.autocmd
    for augroup_name, autocommands in pairs(options.autocmds) do
      for _, autocommand in ipairs(autocommands) do
        autocmd(
          autocommand.event,
          vim.tbl_extend('force', autocommand.opts, {
            group = augroup(augroup_name),
          })
        )
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

  vim.schedule(resume_loading)
end

-- Create user commands on init (async)
-- local function on_init_create_user_commands_async(options)
--   --- @async
--   local init_co = coroutine.create(function()
--     for _, info in pairs(options) do
--       create_single_user_command(info)
--       coroutine.yield()
--     end
--   end)

--   local function resume_loading()
--     if coroutine.status(init_co) ~= 'dead' then
--       coroutine.resume(init_co)
--       vim.defer_fn(resume_loading, 50)
--     end
--   end

--   vim.schedule(resume_loading)
-- end

return setup_au_async
