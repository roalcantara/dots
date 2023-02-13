local handlers = require('neo/etc/lsp/handlers')
local capabilities = require('neo/etc/lsp/capabilities')
local server_config = require('core/paths/path').lsp.config
local set_buf_keymap = require('core/map/set_buf_keymap').set_buf_keymap
local opts = {
  noremap = true,
  silent = false
}
local build_on_attach
build_on_attach = function(mappings)
  return function(client, bufnr)
    local nmap
    nmap = function(keys, func, desc)
      if desc then
        desc = "LSP: " .. tostring(desc)
      end
      return vim.keymap.set('n', keys, func, {
        buffer = bufnr,
        desc = desc
      })
    end
    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    local builtinStatus, builtin = pcall(require, 'telescope.builtin')
    if builtinStatus and builtin then
      nmap('gr', builtin.lsp_references, '[G]oto [R]eferences')
      nmap('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
      nmap('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
    end
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
      return print(vim.inspect(vim.lsp.buf.list_workspace_folders())), '[W]orkspace [L]ist Folders'
    end)
    if mappings then
      for command, mapping in pairs(mappings) do
        set_buf_keymap(bufnr, mapping[1], mapping[2], command, opts)
      end
    end
    for _index_0 = 1, #capabilities do
      local capability = capabilities[_index_0]
      capability(client, bufnr, opts)
    end
    for _index_0 = 1, #handlers do
      local handler = handlers[_index_0]
      handler(client, bufnr, opts)
    end
    return vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
      if vim.lsp.buf.format then
        vim.lsp.buf.format()
      end
      if vim.lsp.buf.formatting then
        return vim.lsp.buf.formatting()
      end
    end, {
      desc = 'Format current buffer with LSP'
    })
  end
end
local load_capabilities
load_capabilities = function()
  capabilities = vim.lsp.protocol.make_client_capabilities()
  return require('cmp_nvim_lsp').default_capabilities(capabilities)
end
local build_capabilities
build_capabilities = function(capabilities_updater)
  if capabilities_updater and type(capabilities_updater) == 'function' then
    return capabilities_updater(load_capabilities())
  end
  return load_capabilities()
end
local get_defaults
get_defaults = function(mappings, capabilities_updater)
  return {
    capabilities = build_capabilities(capabilities_updater),
    on_attach = build_on_attach(mappings)
  }
end
local build_settings
build_settings = function(lang, mappings, capabilities_updater)
  local defaults = get_defaults(mappings, capabilities_updater)
  local config_path = server_config(lang)
  local status, config_factory = pcall(require, config_path)
  if (status) then
    return config_factory(defaults.on_attach, defaults.capabilities)
  else
    return defaults
  end
end
return build_settings
