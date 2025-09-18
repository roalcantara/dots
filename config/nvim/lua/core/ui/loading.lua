local success, pcall_result = pcall(require, 'notify')

local nvim_notify

if success then
  nvim_notify = pcall_result
end

local M = {}

local config = {
  spinner = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' },
}

--- Storage for the current notification and timer
--- @type {notify_record: table|nil, timer: number|nil, is_running: boolean}
local current_notification = {
  notify_record = nil,
  timer = nil,
  is_running = false,
  on_done = {
    title = nil,
    message = nil,
  },
}

local function get_notify_options(default_opts, options)
  local overrides = {}

  for _, opts in ipairs(options) do
    for key, value in pairs(opts) do
      overrides[key] = value
    end
  end

  return vim.tbl_deep_extend('force', {}, default_opts, overrides)
end

local function format_notification_msg(message, spinner_idx)
  if spinner_idx == 0 or spinner_idx == nil then
    return string.format(' %s ', message)
  end

  return string.format(' %s %s ', config.spinner[spinner_idx], message)
end

--- Start the loading notification with spinning animation
--- @param title string The title to display
M.run = function(title)
  local spinner_idx = 1

  current_notification.is_running = true

  local notify_config = {
    id = 'loading_notification_id',
    title = title,
  }

  local function update_spinner()
    -- Create/update the notification using vim.notify with replace
    current_notification.notify_record = vim.notify(
      format_notification_msg(title, spinner_idx),
      vim.log.levels.INFO,
      get_notify_options(
        notify_config,
        current_notification.notify_record and { replace = current_notification.notify_record.id } or {}
      )
    )

    -- Move to next spinner frame
    spinner_idx = spinner_idx + 1
    if spinner_idx > #config.spinner then
      spinner_idx = 1
    end

    if current_notification.is_running then
      vim.defer_fn(update_spinner, 125)
    else
      vim.notify(
        current_notification.on_done.message,
        vim.log.levels.INFO,
        get_notify_options(
          notify_config,
          {
            replace = current_notification.notify_record.id,
            timeout = 2000,
            title = current_notification.on_done.title,
          }
        )
      )
    end
  end

  -- Start the spinner animation
  update_spinner()
end

--- Check if the loading notification is currently running
--- @return boolean
function M.is_running()
  return current_notification.is_running
end

M.stop = function(title, on_done_message)
  current_notification.on_done.title = title
  current_notification.on_done.message = on_done_message
  current_notification.is_running = false
end

return M
