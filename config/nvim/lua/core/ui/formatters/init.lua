local M = {}

local status = require('core.ui.formatters.status')
local modal = require('core.ui.formatters.modal')
local icons = require('core.ui.icons.icons_list')

-- Create the lualine component for formatters
--- @return function Lualine component function
function M.create_lualine_component()
  return function()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

    -- Skip if no filetype
    if filetype == '' then
      return ''
    end

    -- Get formatter status (async)
    local formatter_status = status.get_formatter_status(bufnr)

    -- Return empty if no formatters
    if formatter_status.total == 0 then
      return ''
    end

    local components = {}

    -- Add enabled formatters
    for _, formatter_name in ipairs(formatter_status.enabled) do
      local icon = icons.formatters[formatter_name] or icons.formatters.added
      table.insert(components, string.format('%%#DiagnosticOk#%s%%*', icon))
    end

    -- Add disabled formatters
    for _, formatter_name in ipairs(formatter_status.disabled) do
      local icon = icons.formatters[formatter_name] or icons.formatters.removed
      table.insert(components, string.format('%%#DiagnosticError#%s%%*', icon))
    end

    return table.concat(components, ' ')
  end
end

-- Create click handler for the component
--- @return function Click handler function
function M.create_click_handler()
  return function()
    local bufnr = vim.api.nvim_get_current_buf()
    modal.show_formatter_modal(bufnr)
  end
end

-- Get formatter status for external use
--- @param bufnr number|nil Buffer number
--- @return table Formatter status
function M.get_status(bufnr)
  return status.get_formatter_status(bufnr)
end

-- Show modal for external use
--- @param bufnr number|nil Buffer number
function M.show_modal(bufnr)
  modal.show_formatter_modal(bufnr)
end

-- Toggle modal for external use
--- @param bufnr number|nil Buffer number
function M.toggle_modal(bufnr)
  modal.toggle_modal(bufnr)
end

-- Clear cache for external use
--- @param bufnr number|nil Buffer number
function M.clear_cache(bufnr)
  status.clear_cache(bufnr)
end

-- Refresh formatter status (clear cache and update)
--- @param bufnr number|nil Buffer number
--- @return table Formatter status
function M.refresh(bufnr)
  status.clear_cache(bufnr)
  return status.get_formatter_status(bufnr)
end

-- Create user command for testing
vim.api.nvim_create_user_command('FormatterStatus', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local formatter_status = M.get_status(bufnr)

  if formatter_status.total == 0 then
    vim.notify('No formatters configured for this filetype', vim.log.levels.INFO)
    return
  end

  local message = string.format(
    'Formatters for %s: %d enabled, %d disabled',
    vim.api.nvim_buf_get_option(bufnr, 'filetype'),
    #formatter_status.enabled,
    #formatter_status.disabled
  )

  vim.notify(message, vim.log.levels.INFO)
end, { desc = 'Show formatter status for current buffer' })

vim.api.nvim_create_user_command('FormatterModal', function()
  M.show_modal()
end, { desc = 'Show formatter modal' })

return M
