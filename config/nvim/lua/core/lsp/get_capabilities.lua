-- Native Neovim LSP capabilities configuration
-- Using only built-in Neovim 0.11+ LSP features
-- NO external completion plugins required

local get_capabilities = function(current)
  local current_capabilities = current or {
    textDocument = {
      foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true
      },
      completion = {
        dynamicRegistration = false,
        completionItem = {
          snippetSupport = true,
          commitCharactersSupport = true,
          documentationFormat = { "markdown", "plaintext" },
          deprecatedSupport = true,
          preselectSupport = true,
          tagSupport = {
            valueSet = { 1 }
          },
          insertReplaceSupport = true,
          resolveSupport = {
            properties = { "documentation", "detail", "additionalTextEdits" }
          },
          insertTextModeSupport = {
            valueSet = { 1, 2 }
          }
        },
        completionItemKind = {
          valueSet = vim.tbl_values(vim.lsp.protocol.CompletionItemKind)
        },
        contextSupport = true
      }
    }
  }

  local client_capabilities = vim.lsp.protocol.make_client_capabilities() or {}

  return vim.tbl_deep_extend('force', client_capabilities, current_capabilities)
end

return get_capabilities
