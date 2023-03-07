handlers = require 'opt/lsp/constants/handlers'

-- Builds a "textDocument/formatting" handler.
-- Formats the current buffer.
-- https://microsoft.github.io/language-server-protocol/specification#textDocument_formatting
-- https://github.com/neovim/neovim/blob/master/runtime/doc/lsp.txt#L939
---@param client any Client.
---@return table | nil handler textDocument/formatting handler
build = (client, _, _)->
  if client.server_capabilities.document_formatting
    vim.lsp.handlers[handlers.textDocument.formatting] = (err, _, result, _, bufnr)->
      return if err ~= nil or result == nil
      if not vim.api.nvim_buf_get_option(bufnr, 'modified')
        view = vim.fn.winsaveview!
        vim.lsp.util.apply_text_edits(result, bufnr)
        vim.fn.winrestview(view)
        vim.api.nvim_command('noautocmd :update') if bufnr == vim.api.nvim_get_current_buf!
  else
    return nil

return build
