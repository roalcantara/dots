local build
build = function(client, _, _)
  if client.server_capabilities.document_highlight then
    return vim.api.nvim_exec([[    augroup LspDocumentHighlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
    augroup END
  ]], false)
  end
end
return build
