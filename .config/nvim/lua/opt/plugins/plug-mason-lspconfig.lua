return _G.imports('mason-lspconfig', function(plugin)
  return plugin.setup({
    ensure_installed = { },
    automatic_installation = true
  })
end)
