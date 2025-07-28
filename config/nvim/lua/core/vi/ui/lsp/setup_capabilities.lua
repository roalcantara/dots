local maps = require('core/vi/maps')
local augroup = maps.augroup
local autocmd = maps.autocmd
local should_show_hover = require('core/vi/ui/lsp/hover_filter').should_show_hover

local M = {
  enabled_capabilities = {},
  disabled_capabilities = {},
}
M.enabled_capabilities['textDocument/documentHighlight'] = {
  --- Highlight symbol under cursor on cursor hold and clear on cursor move
  --- @param opts table { buffer = number }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide/
  highlight_symbol_under_cursor = function(opts)
    local buffer = opts.buffer
    local group = augroup('highlight_symbol_under_cursor', { clear = false })

    -- Clear the autocmds for the buffer
    vim.api.nvim_clear_autocmds({ buffer = buffer, group = group })

    -- Highlight symbols under the cursor after the time set at vim.opt.updatetime
    -- https://neovim.io/doc/user/lsp.html#vim.lsp.buf.document_highlight()
    autocmd({ 'CursorHold', 'CursorHoldI' }, {
      group = group,
      buffer = buffer,
      callback = vim.lsp.buf.document_highlight,
      desc = 'Highlight symbol under cursor on cursor hold',
    })

    -- Clear the highlight when the cursor moves
    -- https://neovim.io/doc/user/lsp.html#vim.lsp.buf.clear_references()
    autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group,
      buffer = buffer,
      callback = vim.lsp.buf.clear_references,
      desc = 'Clear symbol under cursor highlights on cursor moves',
    })
  end,
}
M.enabled_capabilities['textDocument/hover'] = {
  --- Shows hover documentation only for meaningful code elements
  --- Excluding simple strings, brackets, punctuation, and other basic elements
  --- @param opts table { buffer = number }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  on_cursor_hold_show_hover_documentation = function(opts)
    if not should_show_hover() then
      return
    end

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

    -- Function to start mouse hover timer
    local function start_mouse_hover_timer()
      clear_mouse_hover_timer()
      mouse_hover_timer = vim.loop.new_timer()
      if mouse_hover_timer then
        mouse_hover_timer:start(mouse_hover_delay, 0, function()
          vim.schedule(function()
            if should_show_hover() then
              show_hover()
            end
          end)
        end)
      end
    end

    -- Mouse hover events with delay (using CursorMoved to detect mouse movement)
    autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group,
      buffer = buffer,
      callback = start_mouse_hover_timer, -- Start timer for mouse hover delay,
      desc = 'Show hover documentation on cursor hold for a while',
    })

    -- Clear mouse hover timer when leaving the buffer
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
M.enabled_capabilities['textDocument/completion'] = {
  -- Enable LSP auto-completion
  -- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  enable_completion = function(opts)
    vim.lsp.completion.enable(true, opts.client.id, opts.buffer, { auto_trigger = true })
  end,
}
M.disabled_capabilities['textDocument/formatting'] = {
  --- Format the buffer on save
  --- @param opts table { buffer = number }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  on_save_formats_buffer = function(opts)
    local buffer = opts.buffer
    local group = augroup('format_on_save', { clear = false })

    -- Clear the autocmds for the buffer
    vim.api.nvim_clear_autocmds({ buffer = buffer, group = group })

    local buf_format = function(e)
      vim.lsp.buf.format({
        bufnr = e.buf,
        async = false,
        timeout_ms = 10000,
      })
    end

    -- On save, format the buffer
    autocmd('BufWritePre', {
      buffer = buffer,
      group = group,
      desc = 'Format current buffer',
      callback = buf_format,
    })
  end,
}
M.disabled_capabilities['textDocument/completion'] = {
  --- Show next and previous completion items on insert
  --- @param opts table { buffer = number }
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  on_insert_shows_completion_menu = function(opts)
    -- Prepares the completion options
    vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'noinsert' }
    vim.opt.shortmess:append('c')

    -- Gets the buffer number
    local buffer = opts.buffer

    -- Handles the next item in the completion menu
    local function tab_next()
      -- When the completion menu is visible
      if vim.fn.pumvisible() == 1 then
        -- Then, navigate to next item in the completion menu
        return '<Down>'
      end

      -- When the completion menu is not visible
      local c = vim.fn.col('.') - 1
      local is_whitespace = c == 0 or vim.fn.getline('.'):sub(c, c):match('%s')
      -- When the cursor is in a whitespace character
      if is_whitespace then
        -- Then, insert a tab character
        return '<Tab>'
      end

      -- When the LSP can provide code completion
      local lsp_completion = vim.bo.omnifunc == 'v:lua.vim.lsp.omnifunc'
      if lsp_completion then
        -- Then, trigger LSP completion
        return '<C-x><C-o>'
      end

      -- Otherwise, uses words found in the current buffer in the completion menu
      return '<C-x><C-n>'
    end

    -- Handles the previous item in the completion menu
    local function tab_prev()
      -- When the completion menu is visible
      if vim.fn.pumvisible() == 1 then
        -- Then, navigate to previous item in the completion menu
        return '<Up>'
      end

      -- Otherwise, insert a tab character
      return '<Tab>'
    end

    -- Set the keymaps to show completion menu on insert
    vim.keymap.set(
      'i',
      '<Tab>',
      tab_next,
      { expr = true, buffer = buffer, desc = 'Show next completion item on insert' }
    )
    vim.keymap.set(
      'i',
      '<S-Tab>',
      tab_prev,
      { expr = true, buffer = buffer, desc = 'Show previous completion item on insert' }
    )
  end,
}

--- Add features for each capability method supported by LSP
--- @param server string LSP name
--- @param lspconfig_opts table LSP config options
--- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
local setup_capabilities_features = function(server, lspconfig_opts)
  -- For each LSP capability method
  for method, features in pairs(M.enabled_capabilities) do
    -- When the capability method is supported by the LSP
    LazyVim.lsp.on_supports_method(method, function(client, buffer)
      -- When the LSP client and buffer are valid
      if type(client) ~= nil and vim.api.nvim_buf_is_valid(buffer) then
        -- For each feature defined for the supported capability method
        for name, feature in pairs(features) do
          -- Setup the feature to the LSP client and buffer
          feature({
            server = server,
            lspconfig_opts = lspconfig_opts,
            client = client,
            buffer = buffer,
          })
          -- Logs that the feature has been added to the LSP client and buffer
          -- Snacks.debug.log(string.format("[%s] (%s) Setup feature '%s' ✔", server, method, name))
        end
      end
    end)
  end
end

return setup_capabilities_features
