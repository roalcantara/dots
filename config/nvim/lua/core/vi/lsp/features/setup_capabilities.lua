local augroup = require('core/vi/au/aug')
local autocmd = require('core/vi/au/au')

local M = {
  enabled_capabilities = {
    ['textDocument/documentHighlight'] = require('core/vi/lsp/features/text_document/document_highlight'),
    ['textDocument/hover'] = require('core/vi/lsp/features/text_document/hover'),
    -- ['textDocument/completion'] = require('core/vi/lsp/features/text_document/completion'),
  }
}

local function on_supports_method(method, client, bufnr)
  if vim.fn.has 'nvim-0.11' == 1 then
    return client:supports_method(method, bufnr)
  else
    return client.supports_method(method, { bufnr = bufnr })
  end
end

--- Add features for each capability method supported by LSP
--- @param client string LSP name
--- @param buffer? table LSP config options
--- @param event? string LSP event name
--- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
local setup_capabilities = function(client, buffer, event)
  -- For each LSP capability method
  for method, features in pairs(M.enabled_capabilities) do
    -- When the capability method is supported by the LSP
    if on_supports_method(method, client, buffer) then
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
        -- Snacks.debug.log(string.format("[%s] (%s) Setup feature '%s' ✔", server, method, name))
      end
    end
  end
end

return setup_capabilities
