local M = {}

-- Auto-dismiss timers for different message types
local dismiss_timers = {}
local dismiss_timeouts = {
  message = 3000, -- 3 seconds for general messages
  command = 2000, -- 2 seconds for command messages
  mode = 1500,    -- 1.5 seconds for mode messages
  search = 4000,  -- 4 seconds for search messages
  dap = 5000,     -- 5 seconds for DAP messages
}

-- Clear a specific message type
--- @param message_type string Type of message to clear
local function clear_message(message_type)
  local noice = require('noice').api.status
  if noice and noice[message_type] and noice[message_type].clear then
    noice[message_type].clear()
  end
end

-- Start auto-dismiss timer for a message type
--- @param message_type string Type of message to auto-dismiss
--- @param timeout_ms number|nil Custom timeout in milliseconds
local function start_dismiss_timer(message_type, timeout_ms)
  -- Clear existing timer if any
  if dismiss_timers[message_type] then
    dismiss_timers[message_type]:stop()
  end

  local timeout = timeout_ms or dismiss_timeouts[message_type]
  if not timeout then
    return
  end

  -- Create new timer
  dismiss_timers[message_type] = vim.loop.new_timer()
  dismiss_timers[message_type]:start(timeout, 0, function()
    -- Clear the message asynchronously
    vim.schedule(function()
      clear_message(message_type)
      -- Refresh statusline to update display
      require('lualine').refresh({ scope = 'statusline' })
    end)
  end)
end

-- Enhanced noice component factory with auto-dismiss
--- @param component_name string Component name
--- @param color_name string Color name
--- @param timeout_ms number|nil Custom timeout in milliseconds
--- @return table Enhanced component with auto-dismiss
function M.create_noice_component_with_dismiss(component_name, color_name, timeout_ms)
  return {
    function()
      local noice = require('noice').api.status
      if not noice or not noice[component_name] then
        return ''
      end

      local message = noice[component_name].get()

      -- If there's a message, start auto-dismiss timer
      if message and message ~= '' then
        start_dismiss_timer(component_name, timeout_ms)
      end

      return message
    end,
    cond = function()
      local noice = require('noice').api.status
      return noice and noice[component_name] and noice[component_name].has()
    end,
    color = function()
      return { fg = require('core.ui.statusline').get_color_by_name(color_name) }
    end,
  }
end

-- Enhanced package component factory with auto-dismiss
--- @param props table Component properties
--- @param timeout_ms number|nil Custom timeout in milliseconds
--- @return table Enhanced component with auto-dismiss
function M.create_package_component_with_dismiss(props, timeout_ms)
  return {
    function()
      local package = require('core.ui.statusline').get_package(props.package)
      if not package then
        return ''
      end

      local result = props.eval_fn(package)

      -- If there's content, start auto-dismiss timer
      if result and result ~= '' then
        start_dismiss_timer(props.package, timeout_ms)
      end

      return result
    end,
    icons_enabled = type(props.icon) ~= 'nil',
    icon = props.icon,
    cond = function()
      local package = require('core.ui.statusline').get_package(props.package)
      return package and props.cond_fn(package)
    end,
    color = function()
      return { fg = require('core.ui.statusline').get_color_by_name(props.color or 'Statement') }
    end,
    on_click = props.on_click,
  }
end

-- Clear all dismiss timers
function M.clear_all_timers()
  for message_type, timer in pairs(dismiss_timers) do
    if timer then
      timer:stop()
      dismiss_timers[message_type] = nil
    end
  end
end

-- Set custom timeout for a message type
--- @param message_type string Message type
--- @param timeout_ms number Timeout in milliseconds
function M.set_timeout(message_type, timeout_ms)
  dismiss_timeouts[message_type] = timeout_ms
end

-- Get current timeout for a message type
--- @param message_type string Message type
--- @return number|nil Timeout in milliseconds
function M.get_timeout(message_type)
  return dismiss_timeouts[message_type]
end

-- Manual dismiss for a specific message type
--- @param message_type string Message type to dismiss
function M.dismiss(message_type)
  clear_message(message_type)
  require('lualine').refresh({ scope = 'statusline' })
end

-- Create user commands for controlling auto-dismiss
vim.api.nvim_create_user_command('AutoDismissClear', function(opts)
  if opts.args and opts.args ~= '' then
    M.dismiss(opts.args)
  else
    M.clear_all_timers()
    vim.notify('All auto-dismiss timers cleared', vim.log.levels.INFO)
  end
end, {
  nargs = '?',
  complete = function()
    return { 'message', 'command', 'mode', 'search', 'dap' }
  end,
  desc = 'Clear auto-dismiss timer for specific message type or all timers'
})

vim.api.nvim_create_user_command('AutoDismissSetTimeout', function(opts)
  local args = vim.split(opts.args, ' ')
  if #args ~= 2 then
    vim.notify('Usage: AutoDismissSetTimeout <type> <timeout_ms>', vim.log.levels.ERROR)
    return
  end

  local message_type = args[1]
  local timeout_ms = tonumber(args[2])

  if not timeout_ms then
    vim.notify('Timeout must be a number', vim.log.levels.ERROR)
    return
  end

  M.set_timeout(message_type, timeout_ms)
  vim.notify(string.format('Set %s timeout to %dms', message_type, timeout_ms), vim.log.levels.INFO)
end, {
  nargs = 1,
  complete = function()
    return { 'message', 'command', 'mode', 'search', 'dap' }
  end,
  desc = 'Set custom timeout for a message type'
})

return M
