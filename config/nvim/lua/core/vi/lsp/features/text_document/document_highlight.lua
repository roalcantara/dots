local M = {
  --- Highlight symbol under cursor on cursor hold and clear on cursor move
  --- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide/
  highlight_symbol_under_cursor = function(opts)
    local buffer = opts.buffer
    local augroup = opts.augroup
    local autocmd = opts.autocmd

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

    autocmd('LspDetach', {
      group = augroup('lsp-detach'),
      callback = function(ev)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = ev.buf }
      end,
      desc = '[LSP] Clear symbol under cursor highlighting on detach',
    })
  end,
}

return M
