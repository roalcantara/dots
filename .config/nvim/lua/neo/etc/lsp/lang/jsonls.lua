local custom_schema = { }
local custom_schemas = {
  custom_schema = custom_schema
}
require('neo/lib/functions/imports')('schemastore', function(plugin)
  return vim.list_extend(custom_schemas, plugin.json.schemas())
end)
local build
build = function(on_attach, capabilities)
  return {
    on_attach = on_attach,
    capabilities = capabilities,
    settings = {
      json = {
        schemas = custom_schemas
      }
    }
  }
end
return build
