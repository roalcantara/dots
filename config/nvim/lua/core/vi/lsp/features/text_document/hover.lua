local M = {
  --- Shows hover documentation only for meaningful code elements
  --- Excluding simple strings, brackets, punctuation, and other basic elements
  --- @param opts table { buffer = number }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  on_cursor_hold_show_hover_documentation = function(opts)
    local should_show_hover = require('core/vi/lsp/utils/hover_filter').should_show_hover

    if not should_show_hover() then
      return
    end

    local augroup = opts.augroup
    local autocmd = opts.autocmd
    local buffer = opts.buffer
    local group = augroup('on_cursor_hold_show_hover_documentation', { clear = false })
    local mouse_hover_timer = nil
    local mouse_hover_delay = vim.g.lsp_hover_mouse_delay or 500 -- Configurable delay for mouse hover

    -- Clear the autocmds for the buffer
    vim.api.nvim_clear_autocmds({ buffer = buffer, group = group })

    -- Function to show hover documentation
    local function show_hover()
      return vim.lsp.buf.hover({
        focusable = false,
        focus = false,
        close_events = { 'CursorMoved', 'CursorMovedI', 'InsertCharPre', 'FocusLost', 'FocusGained' },
      })
    end

    -- Function to clear mouse hover timer
    local function clear_mouse_hover_timer()
      if mouse_hover_timer then
        mouse_hover_timer:stop()
        mouse_hover_timer:close()
        mouse_hover_timer = nil
      end
    end

    -- Check for any completion menu (more generic approach)
    local function is_completion_visible()
      -- Check blink.cmp
      if package.loaded['blink.cmp'] then
        local blink = require('blink.cmp')
        if blink.is_visible() or blink.is_menu_visible() or blink.is_documentation_visible() then
          return true
        end
      end

      -- Check for other completion plugins if needed
      -- if package.loaded['cmp'] then
      --   local cmp = require('cmp')
      --   if cmp.visible() then
      --     return true
      --   end
      -- end

      return false
    end

    -- Function to start mouse hover timer
    local function start_mouse_hover_timer()
      clear_mouse_hover_timer()
      mouse_hover_timer = vim.loop.new_timer()
      if mouse_hover_timer then
        mouse_hover_timer:start(mouse_hover_delay, 0, function()
          vim.schedule(function()
            -- Only show hover if completion menu is not visible and should_show_hover returns true
            if not is_completion_visible() and should_show_hover() then
              show_hover()
            end
          end)
        end)
      end
    end

    autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group,
      buffer = buffer,
      callback = start_mouse_hover_timer, -- Start timer for mouse hover delay,
      desc = 'Show hover documentation on cursor hold for a while',
    })

    autocmd({ 'BufLeave' }, {
      group = group,
      buffer = buffer,
      callback = clear_mouse_hover_timer,
      desc = 'Clear mouse hover timer when leaving buffer',
    })

    -- Clear mouse hover on <Esc>
    vim.schedule(function()
      vim.keymap.set('n', '<Esc>', function()
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
      end, { buffer = buffer, nowait = true, noremap = true, desc = 'Clear LSP hover on <Esc>' })
    end)
  end,
}

return M
