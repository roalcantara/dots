local set_buf_keymap = require('etc/map/set_buf_keymap')
local build
build = function(client, bufnr, opts)
  if client.server_capabilities.document_formatting then
    vim.api.nvim_exec([[      augroup LspFormatOnSave
        autocmd! * <buffer>
        autocmd BufWritePre * lua vim.lsp.buf.formatting_sync(nil, 300)
        augroup END
        ]], true)
    return set_buf_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  elseif client.server_capabilities.document_range_formatting then
    return set_buf_keymap(bufnr, 'n', '<space>f', '<cmd>lua vim.lsp.buf.range_formatting()<CR>', opts)
  end
end
return build
