handlers = require('opt/lsp/handlers')
capabilities = require('opt/lsp/capabilities')
server_config = require('etc/fn/path').lsp.config
set_buf_keymap = require('etc/map/set_buf_keymap').set_buf_keymap
opts = {noremap: true, silent: false}

-- LSP settings.
--  This function gets run when an LSP connects to a particular buffer.
build_on_attach = (mappings)->
  (client, bufnr)->
    -- NOTE: Remember that lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself
    -- many times.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    nmap = (keys, func, desc)->
      desc = "LSP: #{desc}" if desc
      vim.keymap.set('n', keys, func, { buffer: bufnr, :desc })

    nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
    builtinStatus, builtin = pcall(require, 'telescope.builtin')
    if builtinStatus and builtin
      nmap('gr', builtin.lsp_references, '[G]oto [R]eferences')
      nmap('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
      nmap('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', ()-> print(vim.inspect(vim.lsp.buf.list_workspace_folders!)), '[W]orkspace [L]ist Folders')

    if mappings then
      for command, mapping in pairs(mappings)
        set_buf_keymap(bufnr, mapping[1], mapping[2], command, opts)

    for capability in *capabilities
      capability(client, bufnr, opts)

    for handler in *handlers
      handler(client, bufnr, opts)

    -- Create a command `:Format` local to the LSP buffer
    vim.api.nvim_buf_create_user_command(bufnr, 'Format',
      (_)->
        vim.lsp.buf.format! if vim.lsp.buf.format
        vim.lsp.buf.formatting! if vim.lsp.buf.formatting
      { desc: 'Format current buffer with LSP' }
    )


--- nvim-cmp supports additional completion capabilities
---@return table
load_capabilities = ()->
  capabilities = vim.lsp.protocol.make_client_capabilities!
  require('cmp_nvim_lsp').default_capabilities(capabilities)

---Builds the server capabilities
---@param capabilities_updater function | nil The function to be called to update the capabilities
---@return table settings Returns the default settings
build_capabilities = (capabilities_updater)->
  return capabilities_updater(load_capabilities!) if capabilities_updater and type(capabilities_updater) == 'function'
  load_capabilities!

---Gets default settings
---@param mappings table The mappings to be applied
---@param capabilities_updater function | nil The function to be called to update the capabilities
---@return table settings Returns the default settings
get_defaults = (mappings, capabilities_updater)->
  {capabilities: build_capabilities(capabilities_updater), on_attach: build_on_attach(mappings)}

---Gets the language server settings
---@param lang string The language name
---@param mappings table The mappings to be applied
---@param capabilities_updater function | nil The function to be called to update the capabilities
---@return table settings Returns the default settings
build_settings = (lang, mappings, capabilities_updater)->
  defaults = get_defaults(mappings, capabilities_updater)
  config_path = server_config(lang)
  status, config_factory = pcall(require, config_path)
  if (status)
    config_factory(defaults.on_attach, defaults.capabilities)
  else
    defaults

return build_settings
