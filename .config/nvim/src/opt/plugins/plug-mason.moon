-- LSP: Setup mason so it can manage external tooling
_G.imports 'mason', (plugin) ->
  plugin.setup({
    ui: {
      icons: {
        package_installed: '✓',
        package_pending: '➜',
        package_uninstalled: '✗'
      }
    }
  })
