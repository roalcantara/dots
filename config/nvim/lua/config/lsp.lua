-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#dockerls
vim.lsp.config('dockerls', {
  settings = {
    docker = {
      languageserver = {
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    }
  }
})

vim.lsp.config('lua_ls', {
  -- Command and arguments to start the server.
  cmd = { 'lua-language-server' },

  -- Filetypes to automatically attach to.
  filetypes = { 'lua' },

  -- Sets the "root directory" to the parent directory of the file in the
  -- current buffer that contains either ".luarc.json" or ".luarc.jsonc" file.
  -- Files that share a root directory will reuse the connection to the same LSP server.
  -- Nested lists indicate equal priority, see |vim.lsp.Config|.
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },

  -- Specific settings to send to the server. The schema for this is
  -- defined by the server. For example the schema for lua-language-server
  -- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
    },
  },
})

vim.lsp.enable({
  'lua_ls',
  'bashls',
  'diagnosticls',
  'dockerls',
  'docker_compose_language_service',
  'dockerls',
  'ruby_lsp',
  'vtsls'
})

vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = 'rounded',
    source = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = 'ErrorMsg',
      [vim.diagnostic.severity.WARN] = 'WarningMsg',
    },
  },
})
