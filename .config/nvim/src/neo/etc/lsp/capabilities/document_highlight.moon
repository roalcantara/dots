---Builds document_formatting capability.
---@param client any The LSP client
build = (client, _, _)->
  vim.api.nvim_exec([[
    augroup LspDocumentHighlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
    augroup END
  ]], false) if client.server_capabilities.document_highlight

return build
