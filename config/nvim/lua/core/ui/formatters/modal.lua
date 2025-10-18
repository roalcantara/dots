local M = {}

local status = require('core.ui.formatters.status')
local icons = require('core.ui.icons.icons_list')

-- Modal state
local modal_buf = nil
local modal_win = nil

-- Create the formatter modal
--- @param bufnr number|nil Buffer number
function M.show_formatter_modal(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Close existing modal if open
  M.close_modal()

  -- Get formatter status
  local formatter_status = status.get_formatter_status(bufnr)

  if formatter_status.total == 0 then
    vim.notify('No formatters configured for this filetype', vim.log.levels.INFO)
    return
  end

  -- Create buffer for modal
  modal_buf = vim.api.nvim_create_buf(false, true)

  -- Prepare content
  local lines = {}
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  -- Header
  table.insert(lines, '# Formatters for ' .. filetype)
  table.insert(lines, '')

  -- Enabled formatters
  if #formatter_status.enabled > 0 then
    table.insert(lines, '## Enabled Formatters')
    table.insert(lines, '')

    for _, formatter_name in ipairs(formatter_status.enabled) do
      local details = status.get_formatter_details(formatter_name, bufnr)
      if details then
        local icon = icons.formatters[formatter_name] or icons.formatters.added
        table.insert(lines, string.format('**%s** %s', icon, formatter_name))
        table.insert(lines, string.format('  **cmd**: %s', details.command))
        table.insert(lines, string.format('  **available**: yes'))
        table.insert(lines, string.format('  **description**: %s', details.description))
        if details.url then
          table.insert(lines, string.format('  **url**: %s', details.url))
        end
        table.insert(lines, '')
      end
    end
  end

  -- Disabled formatters
  if #formatter_status.disabled > 0 then
    table.insert(lines, '## Disabled Formatters')
    table.insert(lines, '')

    for _, formatter_name in ipairs(formatter_status.disabled) do
      local details = status.get_formatter_details(formatter_name, bufnr)
      local icon = icons.formatters[formatter_name] or icons.formatters.removed
      table.insert(lines, string.format('**%s** %s', icon, formatter_name))
      table.insert(lines, string.format('  **cmd**: %s', details and details.command or 'N/A'))
      table.insert(lines, string.format('  **available**: no'))
      table.insert(lines, string.format('  **description**: %s', details and details.description or 'Not available'))
      table.insert(lines, '')
    end
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(modal_buf, 0, -1, false, lines)

  -- Set buffer options
  vim.api.nvim_buf_set_option(modal_buf, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(modal_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(modal_buf, 'readonly', true)

  -- Calculate window dimensions
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create floating window
  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded',
    title = 'Formatter Status',
    title_pos = 'center',
  }

  modal_win = vim.api.nvim_open_win(modal_buf, true, opts)

  -- Set window options
  vim.api.nvim_win_set_option(modal_win, 'wrap', true)
  vim.api.nvim_win_set_option(modal_win, 'number', false)
  vim.api.nvim_win_set_option(modal_win, 'relativenumber', false)
  vim.api.nvim_win_set_option(modal_win, 'cursorline', true)

  -- Set keymaps
  vim.api.nvim_buf_set_keymap(modal_buf, 'n', '<Esc>', ':lua require("core.ui.formatters.modal").close_modal()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(modal_buf, 'n', 'q', ':lua require("core.ui.formatters.modal").close_modal()<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(modal_buf, 'n', '<CR>', ':lua require("core.ui.formatters.modal").close_modal()<CR>',
    { noremap = true, silent = true })

  -- Highlight groups for enabled/disabled formatters
  vim.api.nvim_buf_add_highlight(modal_buf, -1, 'DiagnosticOk', 0, 0, -1)

  -- Add highlights for enabled formatters
  local line_num = 0
  for _, line in ipairs(lines) do
    if line:match('^## Enabled Formatters') then
      vim.api.nvim_buf_add_highlight(modal_buf, -1, 'DiagnosticOk', line_num, 0, -1)
    elseif line:match('^## Disabled Formatters') then
      vim.api.nvim_buf_add_highlight(modal_buf, -1, 'DiagnosticError', line_num, 0, -1)
    elseif line:match('^%*%*.*%*%*') and line:match('yes') then
      -- Enabled formatter line
      vim.api.nvim_buf_add_highlight(modal_buf, -1, 'DiagnosticOk', line_num, 0, -1)
    elseif line:match('^%*%*.*%*%*') and line:match('no') then
      -- Disabled formatter line
      vim.api.nvim_buf_add_highlight(modal_buf, -1, 'DiagnosticError', line_num, 0, -1)
    end
    line_num = line_num + 1
  end
end

-- Close the modal
function M.close_modal()
  if modal_win and vim.api.nvim_win_is_valid(modal_win) then
    vim.api.nvim_win_close(modal_win, true)
  end
  if modal_buf and vim.api.nvim_buf_is_valid(modal_buf) then
    vim.api.nvim_buf_delete(modal_buf, { force = true })
  end
  modal_win = nil
  modal_buf = nil
end

-- Toggle the modal
--- @param bufnr number|nil Buffer number
function M.toggle_modal(bufnr)
  if modal_win and vim.api.nvim_win_is_valid(modal_win) then
    M.close_modal()
  else
    M.show_formatter_modal(bufnr)
  end
end

-- Check if modal is open
--- @return boolean True if modal is open
function M.is_open()
  return modal_win and vim.api.nvim_win_is_valid(modal_win) or false
end

return M
