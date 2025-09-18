local MOUSE_HOVER_DELAY = 2500 -- Default delay for mouse hover in milliseconds
local mouse_hover_delay = vim.g.lsp_hover_mouse_delay or MOUSE_HOVER_DELAY -- Configurable delay for mouse hover
local HOVER_DOCS_IS_ENABLED = true
local mouse_hover_timer = nil

--- Function to show hover documentation
local function show_hover()
  return vim.lsp.buf.hover({
    focusable = false,
    focus = false,
    close_events = {
      'CursorMoved',
      'CursorMovedI',
      'FocusLost',
      'FocusGained',
      'InsertCharPre',
      'InsertEnter',
      'InsertLeave',
    },
  })
end

--- Check for any completion menu (more generic approach)
local function is_completion_visible()
  -- Check blink.cmp
  if package.loaded['blink.cmp'] then
    local blink = require('blink.cmp')
    if blink.is_visible() or blink.is_menu_visible() or blink.is_documentation_visible() then
      return true
    end
  end

  return false
end

--- Stop, close and clear mouse hover timer
--- @return vim.loop.Timer|nil Mouse hover timer
local function cancel_mouse_hover_timer()
  if mouse_hover_timer then
    mouse_hover_timer:stop()
    mouse_hover_timer:close()
    mouse_hover_timer = nil
  end
  return mouse_hover_timer
end

--- Start mouse hover timer
--- @return vim.loop.Timer|nil Mouse hover timer
local function start_mouse_hover_timer()
  local should_show_hover = require('core/vi/lsp/utils/hover_filter').should_show_hover
  if not HOVER_DOCS_IS_ENABLED or not should_show_hover() then
    return
  end
  cancel_mouse_hover_timer()
  mouse_hover_timer = vim.loop.new_timer()
  mouse_hover_timer:start(
    mouse_hover_delay,
    0,
    vim.schedule_wrap(function()
      -- Only show hover if completion menu is not visible and should_show_hover returns true
      if not is_completion_visible() and should_show_hover() then
        show_hover()
        mouse_hover_timer:close()
        mouse_hover_timer = nil
      end
    end)
  )
end

local function close_hover_documentation()
  -- Find and close all floating windows (LSP hover windows are typically floating)
  local wins = vim.api.nvim_list_wins()
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      -- Check if this is a floating window (LSP hover windows are floating)
      if config.relative ~= '' then
        vim.api.nvim_win_close(win, true)
      end
    end
  end
  HOVER_DOCS_IS_ENABLED = false
end

local M = {
  --- Shows hover documentation only for meaningful code elements
  --- Excluding simple strings, brackets, punctuation, and other basic elements
  --- @param opts table { buffer = number, augroup = function, autocmd = function }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  on_cursor_hold_show_hover_documentation = function(opts)
    local buffer = opts.buffer
    local autocmd = opts.autocmd
    local group = opts.augroup('on_cursor_hold_show_hover_documentation_' .. tostring(buffer), { clear = false })

    -- Clear the autocmds for the buffer
    vim.api.nvim_clear_autocmds({ buffer = buffer, group = group })

    autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = group,
      buffer = buffer,
      callback = vim.schedule_wrap(function()
        start_mouse_hover_timer()
      end),
      desc = 'Show hover documentation on cursor hold for a while',
    })

    -- Reset the dismissed flag when cursor moves
    autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group,
      buffer = buffer,
      callback = vim.schedule_wrap(function()
        HOVER_DOCS_IS_ENABLED = true
      end),
      desc = 'Reset hover dismissed flag on cursor move',
    })

    -- Clear the highlights when the LSP client detaches
    autocmd('LspDetach', {
      group = group,
      buffer = buffer,
      callback = vim.schedule_wrap(function()
        -- Clean up and delete autocommand when LSP detaches
        vim.api.nvim_clear_autocmds({ group = group, buffer = buffer })
        vim.api.nvim_del_augroup_by_id(group)
      end),
      desc = '[LSP] Clear hover documentation on detach',
    })

    -- Clear mouse hover on <Esc>
    vim.schedule(function()
      vim.keymap.set(
        'n',
        '<Esc>',
        close_hover_documentation,
        { buffer = buffer, nowait = true, noremap = true, desc = 'Clear LSP hover on <Esc>' }
      )
    end)
  end,
}

return M
