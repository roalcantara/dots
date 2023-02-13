handlers = require 'neo/etc/lsp/constants/handlers'

-- Builds a "textDocument/publishDiagnostics" handler.
-- https://microsoft.github.io/language-server-protocol/specification#textDocument_publishDiagnostics
---@param client any
---@return nil | table handler textDocument/publishDiagnostics handler
build = (client, _, _)->
  vim.lsp.handlers[handlers.textDocument.publishDiagnostics] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {underline: true, virtual_text: false, signs: true, update_in_insert: true}) if client.server_capabilities.signature_help

return build
