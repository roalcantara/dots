-- Minimal Neovim configuration
-- https://youtu.be/xGkL2N8w0H4

-- DEBUG MODE
-- By default, vim.log.level is set to vim.log.levels.INFO,
-- so DEBUG messages won't show unless you explicitly lower the log level
-- -----------------------------------------------------------------------------
-- vim.log.level = vim.log.levels.DEBUG
-- nvim --cmd "lua vim.log.level = vim.log.levels.DEBUG"
-- export NVIM_LOG_LEVEL=DEBUG nvim
-- -----------------------------------------------------------------------------

-- Enables or disables the experimental Lua module loader to speed up the loading of Lua modules.
-- • overrides |loadfile()|
-- • adds the Lua loader using the byte-compilation cache
-- • adds the libs loader
-- • removes the default Nvim loader
vim.loader.enable(true)

--- @class NeoOptions
--- @field style 'fancy' | 'minimal' | 'compact' The style of the notification
--- @field timeout number The timeout in milliseconds for the notification
--- @field title string The title of the notification
local DEFAULT_OPTIONS = {
  style = 'fancy',
  timeout = 3000, -- 3 seconds
  title = 'Neo',
}

--- @class Neo
--- @field level number
--- @field debug function
--- @field info function
--- @field warn function
--- @field error function
_G.Neo = {
  -- 0: vim.log.levels.TRACE
  -- 1: vim.log.levels.DEBUG
  -- 2: vim.log.levels.INFO
  -- 3: vim.log.levels.WARN
  -- 4: vim.log.levels.ERROR
  -- 5: vim.log.levels.OFF
  level = vim.log.levels.INFO,

  --- Prints a message to the console if the level is greater than or equal to vim.log.levels.DEBUG
  --- @param message string
  --- @param opts NeoOptions The options for the notification
  --- @example Neo.debug('Hello, world!', { title = 'Debug' })
  debug = function(message, opts)
    if Neo.level <= vim.log.levels.DEBUG then
      Snacks.notifier.notify(
        message,
        vim.log.levels.DEBUG,
        vim.tbl_deep_extend('force', {
          style = DEFAULT_OPTIONS.style,
          timeout = DEFAULT_OPTIONS.timeout,
          title = 'DEBUG',
        }, opts or {})
      )
    end
  end,
  --- Prints a message to the console if the level is greater than or equal to vim.log.levels.INFO
  --- @param message string
  --- @param opts NeoOptions The options for the notification
  info = function(message, opts)
    if Neo.level <= vim.log.levels.INFO then
      Snacks.notifier.notify(
        message,
        vim.log.levels.INFO,
        vim.tbl_deep_extend('force', {
          style = DEFAULT_OPTIONS.style,
          timeout = DEFAULT_OPTIONS.timeout,
          title = 'INFO',
        }, opts or {})
      )
    end
  end,
  --- Prints a message to the console if the level is greater than or equal to vim.log.levels.WARN
  --- @param message string
  --- @param opts NeoOptions The options for the notification
  warn = function(message, opts)
    if Neo.level <= vim.log.levels.WARN then
      Snacks.notifier.notify(
        message,
        vim.log.levels.WARN,
        vim.tbl_deep_extend('force', {
          style = DEFAULT_OPTIONS.style,
          timeout = DEFAULT_OPTIONS.timeout,
          title = 'WARN',
        }, opts or {})
      )
    end
  end,
  --- Prints a message to the console if the level is greater than or equal to vim.log.levels.ERROR
  --- @param message string
  --- @param opts NeoOptions The options for the notification
  error = function(message, opts)
    if Neo.level <= vim.log.levels.ERROR then
      Snacks.notifier.notify(
        message,
        vim.log.levels.ERROR,
        vim.tbl_deep_extend('force', {
          style = DEFAULT_OPTIONS.style,
          timeout = DEFAULT_OPTIONS.timeout,
          title = 'ERROR',
        }, opts or {})
      )
    end
  end,

  -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/mini.lua
  mini = require('core/neo/mini'),
}

-- bootstrap lazy.nvim and your plugins
require('config')
