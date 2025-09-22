--- @class NeoOptions
--- @field style 'fancy' | 'minimal' | 'compact' The style of the notification
--- @field timeout number The timeout in milliseconds for the notification
--- @field title string The title of the notification
local LOG_DEFAULT_OPTIONS = {
  style = 'fancy',
  timeout = 3000, -- 3 seconds
  title = 'Neo',
}

local M = {
  DEFAULT_OPTIONS = LOG_DEFAULT_OPTIONS,
  level = vim.log.levels.INFO,
}

-- 0: vim.log.levels.TRACE
-- 1: vim.log.levels.DEBUG
-- 2: vim.log.levels.INFO
-- 3: vim.log.levels.WARN
-- 4: vim.log.levels.ERROR
-- 5: vim.log.levels.OFF


--- Prints a message to the console if the level is greater than or equal to vim.log.levels.DEBUG
--- @param level number The level of the message
--- @param message string
--- @param opts NeoOptions The options for the notification
--- @example Neo.debug('Hello, world!', { title = 'Debug' })
local log = function(level, message, opts)
  if M.level <= level then
    Snacks.notifier.notify(
      message,
      level,
      vim.tbl_deep_extend('force', {
        style = M.DEFAULT_OPTIONS.style,
        timeout = M.DEFAULT_OPTIONS.timeout,
        title = level,
      }, opts or {})
    )
  end
end

--- Prints a message to the console if the level is greater than or equal to vim.log.levels.DEBUG
--- @param message string
--- @param opts NeoOptions The options for the notification
--- @example Neo.debug('Hello, world!', { title = 'Debug' })
M.debug = function(message, opts)
  log(vim.log.levels.DEBUG, message, opts)
end

--- Prints a message to the console if the level is greater than or equal to vim.log.levels.INFO
--- @param message string
--- @param opts NeoOptions The options for the notification
M.info = function(message, opts)
  log(vim.log.levels.INFO, message, opts)
end

--- Prints a message to the console if the level is greater than or equal to vim.log.levels.WARN
--- @param message string
--- @param opts NeoOptions The options for the notification
M.warn = function(message, opts)
  log(vim.log.levels.WARN, message, opts)
end

--- Prints a message to the console if the level is greater than or equal to vim.log.levels.ERROR
--- @param message string
--- @param opts NeoOptions The options for the notification
M.error = function(message, opts)
  log(vim.log.levels.ERROR, message, opts)
end

return M
