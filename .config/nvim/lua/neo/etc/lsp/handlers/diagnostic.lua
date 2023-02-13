local handlers = require('neo/etc/lsp/constants/handlers')
local build
build = function(client, _, _)
  if client.server_capabilities.signature_help then
    vim.lsp.handlers[handlers.textDocument.publishDiagnostics] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
      underline = true,
      virtual_text = false,
      signs = true,
      update_in_insert = true
    })
  end
end
return build
