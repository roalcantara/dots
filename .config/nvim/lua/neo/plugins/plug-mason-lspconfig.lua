local lsp_enabled = {
  'angularls',
  'bashls',
  'cssls',
  'dockerls',
  'gradle_ls',
  'graphql',
  'html',
  'jsonls',
  'kotlin_language_server',
  'lemminx',
  'rnix',
  'lua_ls',
  'tsserver',
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
