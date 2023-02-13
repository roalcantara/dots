return require('neo/lib/functions/imports')('mason', function(plugin)
  return plugin.setup({
    ui = {
      icons = {
        package_installed = '✓',
        package_pending = '➜',
        package_uninstalled = '✗'
      }
    }
  })
end)
