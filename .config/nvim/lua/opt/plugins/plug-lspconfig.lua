local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
if not cmp_nvim_lsp_status then
  return 
end
return _G.imports('lspconfig', function(lspconfig)
  local build_settings = require('opt/lsp/settings')
  local capabilities_updater = cmp_nvim_lsp.default_capabilities
  local mappings = { }
  return require('mason-lspconfig').setup_handlers({
    function(server_name)
      return lspconfig[server_name].setup(build_settings(server_name, mappings, capabilities_updater))
    end,
    ['gopls'] = function()
      return lspconfig['gopls'].setup(build_settings('gopls', mappings, capabilities_updater))
    end,
    ['jsonls'] = function()
      return lspconfig['jsonls'].setup(build_settings('jsonls', mappings, capabilities_updater))
    end,
    ['lua_ls'] = function()
      return lspconfig['lua_ls'].setup(build_settings('lua_ls', mappings, capabilities_updater))
    end,
    ['tsserver'] = function()
      return lspconfig['tsserver'].setup(build_settings('tsserver', mappings, capabilities_updater))
    end
  })
end)
