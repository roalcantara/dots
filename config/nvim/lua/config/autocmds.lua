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
local function create_single_user_command(info)
  local name, module_path, opts, action = info.cmd, info.module.path, info.opts, info.action

  local module = h.get_module(module_path)
  if not module then
    Snacks.notify.error('Failed to load module: ' .. module_path)
    return false
  end

  local command = h.get_command(module, action)
  if type(command) ~= 'function' and type(command) ~= 'string' then
    Snacks.notify.error('Failed to load command: `' .. name .. '`. Module is not a function or action is not defined!')
    return false
  end

  return vim.api.nvim_create_user_command(name, command, opts or {})
end
h.load_modules = function(options)
  local mods = {}
  for mod_name, mod in pairs(options) do
    mods[mod_name] = h.get_module(mod.path)
  end
  return mods
end

local function on_init_create_autocmd_async(options)
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
local function on_init_create_user_commands_async(options)
  --- @async
  local init_co = coroutine.create(function()
    for _, info in pairs(options) do
      create_single_user_command(info)
      coroutine.yield()
    end
  end)

  local function resume_loading()
    if coroutine.status(init_co) ~= 'dead' then
      coroutine.resume(init_co)
      vim.defer_fn(resume_loading, 50)
    end
  end

  vim.schedule(resume_loading)
end

on_init_create_user_commands_async({
  {
    cmd = 'RealLuaRuntimePath',
    module = { path = 'core/vi/fn/paths' },
    opts = { desc = 'Shows the Real Lua Runtime Path' },
    action = function(paths)
      Snacks.notify.info('Lua Runtime Path: ' .. vim.inspect(paths.lua.runtime.path))
    end,
  },
  {
    cmd = 'RealLuaWorkspaceLibraryPath',
    module = { path = 'core/vi/fn/paths' },
    opts = { desc = 'Shows the Real Lua Workspace Library Path' },
    action = function(paths)
      Snacks.notify.info('Lua Workspace Library Path: ' .. vim.inspect(paths.lua.workspace.library))
    end,
  },
  {
    cmd = 'LspHoverMouseDelay',
    module = { path = 'core/vi/fn/ver' },
    opts = {
      desc = 'Set LSP mouse hover delay in milliseconds',
      nargs = '?',
      complete = function()
        return { '100', '250', '500', '750', '1000' }
      end,
    },
    action = function(ver)
      local args = vim.fn.argv()
      local delay = tonumber(args[1])

      if delay and delay > 0 then
        vim.g.lsp_hover_mouse_delay = delay
        Snacks.notify.info('LSP mouse hover delay set to ' .. delay .. 'ms')
      else
        local current_delay = vim.g.lsp_hover_mouse_delay or 500
        Snacks.notify.info('Current LSP mouse hover delay: ' .. current_delay .. 'ms')
        Snacks.notify.info('Usage: :LspHoverMouseDelay <milliseconds>')
      end
    end,
  },
  {
    cmd = 'DebugHoverFilter',
    module = { path = 'core/vi/ui/lsp/hover_filter' },
    opts = { desc = 'Debug hover filter for current cursor position' },
    action = function(hover_filter)
      local node_info = hover_filter.debug_current_node()
      if node_info then
        Snacks.notify.info('Node type: ' .. node_info.type)
        Snacks.notify.info('Node text: ' .. (node_info.text or 'nil'))
        Snacks.notify.info('Should show hover: ' .. tostring(node_info.should_show_hover))
      else
        Snacks.notify.error('No node found at current cursor position')
      end
    end,
  },
})
on_init_create_autocmd_async({
  modules = {
    augroup = { path = 'core/vi/maps/augroup' },
    autocmd = { path = 'core/vi/maps/autocmd' },
  },
  autocmds = {
    filetypedetect = {
      {
        event = 'BufRead',
        opts = {
          pattern = { '*.yml' },
          command = 'set filetype=yaml',
          desc = 'Setup filetype=yaml for files ended with .yml',
        },
      },
      {
        event = 'BufNewFile',
        opts = {
          pattern = { '*.yml' },
          command = 'set filetype=yaml',
          desc = 'Setup filetype=yaml for files ended with .yml',
        },
      },
    },
    close_with_esc = {
      {
        event = 'FileType',
        opts = {
          pattern = {
            'aerial',
            'checkhealth',
            'dbout',
            'DressingSelect',
            'floaterm',
            'gitsigns-blame',
            'grug-far',
            'help',
            'Jaq',
            'lazy',
            'lir',
            'lsp-installer',
            'lspinfo',
            'LspsagaCodeAction',
            'LspsagaDiagnostic',
            'LspsagaFinder',
            'LspsagaFloaterm',
            'LspsagaHover',
            'LspsagaRename',
            'LspsagaSignatureHelp',
            'LspSignatureHelp',
            'man',
            'markdown',
            'neotest-output-panel',
            'neotest-output',
            'neotest-summary',
            'noice',
            'notify',
            'null-ls-info',
            'PlenaryTestPopup',
            'qf',
            'snacks_notif_history',
            'snacks_notif_log',
            'snacks_notif',
            'snacks_win',
            'snacks_picker_list',
            'spectre_panel',
            'startuptime',
            'trouble',
            'Trouble',
            'TroubleToggle',
            'tsplayground',
            'unix',
            "checkhealth",
            "dbout",
            "gitsigns-blame",
            "grug-far",
            "help",
            "lspinfo",
            "neotest-output-panel",
            "neotest-output",
            "neotest-summary",
            "notify",
            "PlenaryTestPopup",
            "qf",
            "spectre_panel",
            "startuptime",
            "tsplayground",
          },
          callback = function()
            local execute_on_esc = h.get_module('core/vi/maps/execute_on_esc')
            if type(execute_on_esc) == 'function' then
              execute_on_esc({
                on_esc = function(event)
                  vim.cmd('close')
                  pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
                end,
                desc = 'Quit on <Esc>',
              })
            end
          end,
          desc = 'Close buffer with <Esc>',
        },
      },
    },
    on_open_term = {
      {
        event = 'TermOpen',
        opts = {
          callback = function()
            vim.opt.number = false
            vim.opt.relativenumber = false
            vim.cmd('startinsert')
          end,
        },
      },
    },
  },
})
