--- Show all options
local function setup_options_user_command()
  return require('core/map/helper').user_cmd('Options', function()
    return require('core/ui/snacks_helper').pick.options()
  end, 'Show all options')
end

-- Get runtime paths and check for lua directories
local function setup_get_lua_paths_user_command()
  return vim.api.nvim_create_user_command('GetLuaPaths', function()
    local rtp = vim.opt.runtimepath:get()
    local lua_paths = {}

    for _, path in ipairs(rtp) do
      local lua_path = path .. '/lua'
      if vim.fn.isdirectory(lua_path) == 1 then
        table.insert(lua_paths, lua_path)
      end
    end

    local lines = {}
    for _, result in ipairs(lua_paths) do
      table.insert(lines, result)
    end

    Snacks.notify.info(lines, {
      icon = '',
      title = 'Lua paths in runtimepath',
      timeout = false,
      style = 'fancy',
    })
  end, { desc = 'Get Lua library paths' })
end

-- Function to check Lua library paths
local function setup_check_lua_paths_user_command()
  return vim.api.nvim_create_user_command('CheckLuaPaths', function()
    local paths = {
      vim.env.VIMRUNTIME,
      vim.fn.expand('~/.local/share/nvim/lazy/LazyVim/lua'),
      vim.fn.expand('~/.local/share/nvim/lazy'),
      vim.fn.expand('~/.local/share/nvim/mason/packages'),
      '/opt/homebrew/bin/lua-language-server',
    }

    local results = {}
    for _, path in ipairs(paths) do
      local exists = vim.uv.fs_stat(path) ~= nil
      table.insert(results, {
        path = path,
        exists = exists,
        status = exists and '✓' or '✗',
      })
    end

    -- Display results in a floating window
    local lines = {}
    for _, result in ipairs(results) do
      table.insert(lines, string.format('%s %s', result.status, result.path))
    end

    Snacks.notify.info(lines, {
      icon = '',
      title = 'Lua Library Paths Status',
      timeout = false,
      style = 'fancy',
    })
  end, { desc = 'Check Lua library paths' })
end

--
local function setup_list_lsp_handlers_user_command()
  return vim.api.nvim_create_user_command('LspHandlers', function()
    local handlers = vim.lsp.handlers
    local lines = {}

    for method, handler in pairs(handlers) do
      table.insert(lines, string.format('%s: %s', method, tostring(handler)))
    end

    Snacks.notify.info(lines, {
      icon = '',
      title = 'LSP Handlers',
      timeout = false,
      style = 'fancy',
    })
  end, { desc = 'List all LSP handlers' })
end

-- Setup all user commands
setup_options_user_command()
setup_get_lua_paths_user_command()
setup_check_lua_paths_user_command()
setup_list_lsp_handlers_user_command()
