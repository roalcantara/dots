local lsp_enabled = {
  'angularls',
  'bashls',
  'cssls',
  'dockerls',
  'gopls',
  'graphql',
  'html',
  'jsonls',
  'kotlin_language_server',
  'lemminx',
  'rnix',
  'sumneko_lua',
  'taplo',
  'vimls',
  'yamlls',
  'zk'
}
return require('neo/lib/functions/imports')('mason-lspconfig', function(plugin)
  return plugin.setup({
    ensure_installed = lsp_enabled,
    automatic_installation = true
  })
end)
