local autocmd = vim.api.nvim_create_autocmd

--- Handle highlighting symbols under the cursor on hold and clearing on move
--- @param buffer integer Options containing the buffer number
--- @param group string|integer The autogroup to use for the autocmds
--- @see https://neovim.io/doc/user/lsp.html#vim.lsp.buf.document_highlight()
local function handle_symbols_under_cursor_on_hold_or_move(buffer, group)
  -- Highlight symbols under the cursor after the time set at vim.opt.updatetime
  autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = group,
    buffer = buffer,
    callback = vim.schedule_wrap(vim.lsp.buf.document_highlight),
    desc = 'Highlight symbol under cursor on cursor hold',
  })

  -- Clear the highlight when the cursor moves
  -- https://neovim.io/doc/user/lsp.html#vim.lsp.buf.clear_references()
  autocmd({ 'CursorMoved', 'CursorMovedI', 'InsertEnter' }, {
    group = group,
    buffer = buffer,
    callback = vim.schedule_wrap(vim.lsp.buf.clear_references),
    desc = 'Clear symbol under cursor highlights on cursor moves',
  })
end

--- Handle clearing highlights when the LSP client detaches from the buffer
--- @param buffer integer Options containing the buffer number
--- @param group string|integer The autogroup to use for the autocmds
--- @see https://neovim.io/doc/user/lsp.html#vim.lsp.buf.clear_references()
local function clear_symbols_under_cursor_on_detach(buffer, group)
  -- Clear the highlights when the LSP client detaches
  autocmd('LspDetach', {
    group = group,
    buffer = buffer,
    callback = function()
      vim.lsp.buf.clear_references()
      vim.api.nvim_clear_autocmds({ group = group, buffer = buffer })
      -- Clean up autocommands when LSP detaches
      vim.api.nvim_del_augroup_by_id(group)
    end,
    desc = '[LSP] Clear symbol under cursor highlighting on detach',
  })
end

return {
  --- Highlight symbol under cursor on cursor hold and clear on cursor move
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
  highlight_symbol_under_cursor = function(opts)
    local buffer = opts.buffer

    -- Create autocommands for this buffer
    local group = opts.augroup('lsp_highlight_symbol_under_cursor_' .. tostring(buffer), { clear = false })
    vim.api.nvim_clear_autocmds({ group = group, buffer = buffer })

    handle_symbols_under_cursor_on_hold_or_move(buffer, group)
    clear_symbols_under_cursor_on_detach(buffer, group)
  end,
}
