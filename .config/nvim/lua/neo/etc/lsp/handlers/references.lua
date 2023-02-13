local handlers = require('neo/etc/lsp/constants/handlers')
local build
build = function(client, _, _)
  if client.server_capabilities.find_references then
    vim.lsp.handlers[handlers.textDocument.references] = vim.lsp.with(vim.lsp.handlers[handlers.textDocument.references], {
      loclist = true
    })
  else
    return nil
  end
end
return build
