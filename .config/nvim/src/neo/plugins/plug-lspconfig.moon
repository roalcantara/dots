cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
return if not cmp_nvim_lsp_status

-- A GUI library for Neovim plugin developer
-- https://github.com/ray-x/guihua.lua
require('neo/lib/functions/imports') 'lspconfig', (lspconfig) ->
  build_settings = require('neo/etc/lsp/settings')
  capabilities_updater = cmp_nvim_lsp.default_capabilities
  mappings = {}

  require('mason-lspconfig').setup_handlers {
    -- default handler
    -- Called for each installed server that doesn't have a dedicated handler
    (server_name)->
      lspconfig[server_name].setup(build_settings(server_name, mappings, capabilities_updater)),

    -- dedicated handlers
    ['gopls']: ()->
      lspconfig['gopls'].setup(build_settings('gopls', mappings, capabilities_updater)),

    ['jsonls']: ()->
      lspconfig['jsonls'].setup(build_settings('jsonls', mappings, capabilities_updater)),

    ['sumneko_lua']: ()->
      lspconfig['sumneko_lua'].setup(build_settings('sumneko_lua', mappings, capabilities_updater)),

    ['tsserver']: ()->
      lspconfig['tsserver'].setup(build_settings('tsserver', mappings, capabilities_updater)),
  }
