set_bmap = require('core/map/set_buf_keymap').set_bmap

-- https://github.com/jose-elias-alvarez/nvim-lsp-ts-utils
ts_utils_settings = {
  debug: false,
  disable_commands: false,
  enable_import_on_completion: true,

  -- import all
  import_all_timeout: 5000, -- ms
  import_all_priorities: {
    buffers: 4, -- loaded buffer names
    buffer_content: 3, -- loaded buffer content
    local_files: 2, -- git files or files with relative path markers
    same_file: 1 -- add to existing import statement
  },
  import_all_scan_buffers: 100,
  import_all_select_source: false,

  -- eslint
  -- eslint_bin (string): sets the binary used to get ESLint output.
  -- Looks for a executable in node_modules and falls back to a
  -- system-wide executable, which must be available on your $PATH.
  eslint_bin: 'eslint_d',
  -- Uses eslint by default for compatibility,
  -- but I highly, highly recommend using eslint_d.
  -- eslint will add a noticeable delay to each code action.
  eslint_enable_code_actions: true,
  eslint_enable_diagnostics: true,
  eslint_enable_disable_comments: true,
  eslint_opts: {
    condition: (utils)->
      utils.root_has_file('.eslintrc.js'),
    diagnostics_format: '#{m} [#{c}]'
  },

  -- formatting
  enable_formatting: true,
  formatter: 'prettier',
  formatter_opts: {},

  -- update imports on file move
  update_imports_on_move: false,
  require_confirmation_on_move: false,
  watch_dir: nil,

  -- filter diagnostics
  filter_out_diagnostics_by_severity: {},
  -- filter out dumb module warning
  filter_out_diagnostics_by_code: {80001}
}

status, plugin = pcall(require, 'nvim-lsp-ts-utils')

---Builds and returns the on_attach callback for the lsp server.
---https://jose-elias-alvarez.medium.com/configuring-neovims-lsp-client-for-typescript-development-5789d58ea9c
---@param on_attach any
---@return function
build_on_attach = (on_attach)->
  (client, bufnr)->
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
    if (status)
      plugin.setup(ts_utils_settings)
      plugin.setup_client(client)
    set_bmap(bufnr, 'tso', ':TSLspOrganize<CR>')
    set_bmap(bufnr, 'tsr', ':TSLspRenameFile<CR>')
    set_bmap(bufnr, 'tsi', ':TSLspImportAll<CR>')
    set_bmap(bufnr, 'tsf', ':TSLspFixCurrent<CR>')
    vim.opt_local.omnifunc = 'v:lua.vim.lsp.omnifunc'
    on_attach(client, bufnr)

---Builds tsserver configuration
---https://github.com/typescript-language-server/typescript-language-server
---https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#tsserver
---@param on_attach any
---@param capabilities any
---@return table
build = (on_attach, capabilities)->
  {on_attach: build_on_attach(on_attach), :capabilities}

return build
