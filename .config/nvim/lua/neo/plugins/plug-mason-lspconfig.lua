local lsp_enabled = {
  'gradle_ls',
  'graphql',
  'taplo',
  'vimls'
}
return require('neo/lib/functions/imports')('mason-lspconfig', function(plugin)
  return plugin.setup({
    ensure_installed = lsp_enabled,
    automatic_installation = true
  })
end)
