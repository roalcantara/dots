local set_bmap = require('etc/map/set_buf_keymap').set_bmap
local ts_utils_settings = {
  debug = false,
  disable_commands = false,
  enable_import_on_completion = true,
  import_all_timeout = 5000,
  import_all_priorities = {
    buffers = 4,
    buffer_content = 3,
    local_files = 2,
    same_file = 1
  },
  import_all_scan_buffers = 100,
  import_all_select_source = false,
  eslint_bin = 'eslint_d',
  eslint_enable_code_actions = true,
  eslint_enable_diagnostics = true,
  eslint_enable_disable_comments = true,
  eslint_opts = {
    condition = function(utils)
      return utils.root_has_file('.eslintrc.js')
    end,
    diagnostics_format = '#{m} [#{c}]'
  },
  enable_formatting = true,
  formatter = 'prettier',
  formatter_opts = { },
  update_imports_on_move = false,
  require_confirmation_on_move = false,
  watch_dir = nil,
  filter_out_diagnostics_by_severity = { },
  filter_out_diagnostics_by_code = {
    80001
  }
}
local status, plugin = pcall(require, 'nvim-lsp-ts-utils')
local build_on_attach
build_on_attach = function(on_attach)
  return function(client, bufnr)
    client.server_capabilities.document_formatting = false
    client.server_capabilities.document_range_formatting = false
    if (status) then
      plugin.setup(ts_utils_settings)
      plugin.setup_client(client)
    end
    set_bmap(bufnr, 'tso', ':TSLspOrganize<CR>')
    set_bmap(bufnr, 'tsr', ':TSLspRenameFile<CR>')
    set_bmap(bufnr, 'tsi', ':TSLspImportAll<CR>')
    set_bmap(bufnr, 'tsf', ':TSLspFixCurrent<CR>')
    vim.opt_local.omnifunc = 'v:lua.vim.lsp.omnifunc'
    return on_attach(client, bufnr)
  end
end
local build
build = function(on_attach, capabilities)
  return {
    on_attach = build_on_attach(on_attach),
    capabilities = capabilities
  }
end
return build
