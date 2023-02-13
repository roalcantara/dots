custom_schema = {
    --   {
    --     description = 'My Custom JSON schema',
    --     fileMatch = { 'foobar.json', '.foobar.json' },
    --     name = 'foobar.json',
    --     url = 'https://example.com/schema/foobar.json',
    --   },
}
custom_schemas = { :custom_schema }

-- Returns the schemas from the schemastore catalog
-- https://github.com/b0o/SchemaStore.nvim
-- https://www.schemastore.org/json/
require('neo/lib/functions/imports') 'schemastore', (plugin) ->
  vim.list_extend(custom_schemas, plugin.json.schemas!)

-- Builds jsonls configuration
-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#jsonls
-- https://github.com/hrsh7th/vscode-langservers-extracted
-- https://github.com/b0o/SchemaStore.nvim
---@param on_attach any
---@param capabilities any
---@return table
build = (on_attach, capabilities)->
  {:on_attach, :capabilities, settings: {json: {schemas: custom_schemas}}}

return build
