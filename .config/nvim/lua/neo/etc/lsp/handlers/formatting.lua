local handlers = require('neo/etc/lsp/constants/handlers')
local build
build = function(client, _, _)
  if client.server_capabilities.document_formatting then
    vim.lsp.handlers[handlers.textDocument.formatting] = function(err, _, result, _, bufnr)
      if err ~= nil or result == nil then
        return 
      end
      if not vim.api.nvim_buf_get_option(bufnr, 'modified') then
        local view = vim.fn.winsaveview()
        vim.lsp.util.apply_text_edits(result, bufnr)
        vim.fn.winrestview(view)
        if bufnr == vim.api.nvim_get_current_buf() then
          return vim.api.nvim_command('noautocmd :update')
        end
      end
    end
  else
    return nil
  end
end
return build
