set_buf_keymap = require 'etc/map/set_buf_keymap'

-- Builds document_formatting capability.
---@param client any The LSP client
---@param bufnr number Buffer number
---@param opts table Mapping options
build = (client, bufnr, opts)->
  if client.server_capabilities.document_formatting
    vim.api.nvim_exec([[
      augroup LspFormatOnSave
        autocmd! * <buffer>
        autocmd BufWritePre * lua vim.lsp.buf.formatting_sync(nil, 300)
        augroup END
        ]], true)
    set_buf_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  elseif client.server_capabilities.document_range_formatting
    set_buf_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)

return build
