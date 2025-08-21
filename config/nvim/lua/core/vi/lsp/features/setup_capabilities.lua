local augroup = require('core/vi/au/aug')
local autocmd = require('core/vi/au/au')

local M = {
  enabled_capabilities = {
    ['textDocument/documentHighlight'] = require('core/vi/lsp/features/text_document/document_highlight'),
    ['textDocument/hover'] = require('core/vi/lsp/features/text_document/hover'),
  },
}

--- Add features for each capability method supported by LSP
--- @param client table LSP client
--- @param buffer? number LSP config options
--- @param event? table LSP event
--- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
local setup_capabilities = function(client, buffer, event)
  -- For each LSP capability method
  for method, features in pairs(M.enabled_capabilities) do
    -- When the capability method is supported by the LSP
    if client:supports_method(method, buffer) then
      -- For each feature defined for the supported capability method
      for name, feature in pairs(features) do
        -- Setup the feature to the LSP client and buffer
        feature({
          client = client,
          buffer = buffer,
          event = event,
          augroup = augroup,
          autocmd = autocmd,
        })
        -- Logs that the feature has been added to the LSP client and buffer
        Neo.debug(string.format("[%s/%s] (%s) Setup feature '%s' ✔", client.name, event, method, name))
      end
    end
  end
end

return setup_capabilities
