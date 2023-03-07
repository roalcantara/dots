handlers = require 'opt/lsp/constants/handlers'

-- Builds a "textDocument/references" handler.
-- Lists all the references to the symbol under the cursor in the quickfix window.
-- https://microsoft.github.io/language-server-protocol/specification#textDocument_references
-- https://github.com/neovim/neovim/blob/master/runtime/doc/lsp.txt#L1053
---@param client any Client
---@return table | nil handler textDocument/references handler
build = (client, _, _)->
  if client.server_capabilities.find_references
    vim.lsp.handlers[handlers.textDocument.references] = vim.lsp.with(vim.lsp.handlers[handlers.textDocument.references], {loclist: true})
  else
    return nil

return build
