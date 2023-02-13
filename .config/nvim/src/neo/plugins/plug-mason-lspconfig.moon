lsp_enabled = {
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
  'tsserver',
  'taplo',
  'vimls',
  'yamlls',
  'zk'
}

-- A file explorer tree for neovim written in lua
-- https://github.com/kyazdani42/nvim-tree.lua
require('neo/lib/functions/imports') 'mason-lspconfig', (plugin) ->
  plugin.setup({ -- Enable the following language servers
    -- A list of servers to automatically install if they're not already installed.
    -- Example: { 'rust_analyzer@nightly', 'sumneko_lua' }
    -- This setting has no relation with the `automatic_installation` setting.
    ensure_installed: lsp_enabled,
    -- Whether servers that are set up (via lspconfig) should be automatically installed.
    -- This setting has no relation with the `ensure_installed` setting.
    -- Can either be:
    --   - false: Servers are not automatically installed.
    --   - true: All servers set up via lspconfig are automatically installed.
    --   - { exclude: string[] }: All servers set up via lspconfig,
    --       except the ones provided in the list, are automatically installed.
    --       Example: automatic_installation = { exclude = { 'rust_analyzer', 'solargraph' } }
    automatic_installation: true
  })
