local augroup = require('core/vi/au/aug')
local autocmd = require('core/vi/au/au')

local M = {
  enabled_capabilities = {
    [vim.lsp.protocol.Methods.textDocument_documentHighlight] = require('core/vi/lsp/features/text_document/document_highlight'),
    [vim.lsp.protocol.Methods.textDocument_hover] = require('core/vi/lsp/features/text_document/hover'),
    [vim.lsp.protocol.Methods.textDocument_signatureHelp] = require('core/vi/lsp/features/text_document/signature_help'),
    [vim.lsp.protocol.Methods.textDocument_formatting] = require('core/vi/lsp/features/text_document/formatting'),
    [vim.lsp.protocol.Methods.textDocument_inlineCompletion] = require('core/vi/lsp/features/text_document/inline_completion'),
    [vim.lsp.protocol.Methods.textDocument_completion] = require('core/vi/lsp/features/text_document/completion'),
    [vim.lsp.protocol.Methods.textDocument_inlayHint] = require('core/vi/lsp/features/text_document/inlay_hints'),
  }
}

--- Add features for each capability method supported by LSP
--- Not all language servers provide the same capabilities!
--- @param client table LSP client
--- @param buffer? number LSP config options
--- @param opts? table LSP options
--- @see https://vonheikemen.github.io/devlog/tools/neovim-lsp-client-guide
local setup_capabilities = function(client, buffer, opts)
  -- For each LSP capability method
  for method, features in pairs(M.enabled_capabilities) do
    -- Not all language servers provide the same capabilities!
    -- Check server capabilities (in a LSP-enabled buffer) via :lua =vim.lsp.get_clients()[1].server_capabilities
    -- https://neovim.io/doc/user/lsp.html#lsp-attach
    if client:supports_method(method, buffer) then
      -- For each feature defined for the supported capability method
      for name, feature in pairs(features) do
        -- Setup the feature to the LSP client and buffer
        feature({
          client = client,
          buffer = buffer,
          event = opts,
          augroup = augroup,
          autocmd = autocmd,
        })
      end
    end
  end
end

return setup_capabilities
