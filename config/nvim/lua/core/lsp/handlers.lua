local M = {
  neovim = {
    -- Check for Neovim 0.11+ which includes native LSP configuration
    has_native_lsp_api = vim.fn.has('nvim-0.11') == 1 or vim.fn.has('nvim-0.10') == 1 or vim.fn.has('nvim-0.10.0') == 1,
    has_deprecated_sign_api = vim.fn.has('nvim-0.10.0') == 0,
    -- Specific check for 0.11+ features
    has_lsp_config_api = vim.fn.has('nvim-0.11') == 1,
  },
  handlers = {
    ['callHierarchy/incomingCalls'] = {
    },
    ['callHierarchy/outgoingCalls'] = {
    },
    ['client/registerCapability'] = {
    },
    ['client/unregisterCapability'] = {
    },
    ['signature_help'] = {
    },
    ['textDocument/codeLens'] = {
    },
    ['textDocument/completion'] = {
    },
    ['textDocument/diagnostic'] = {
    },
    ['textDocument/documentHighlight'] = {
    },
    ['textDocument/documentSymbol'] = {
    },
    ['textDocument/formatting'] = {
    },
    ['textDocument/hover'] = {
    },
    ['textDocument/inlayHint'] = {
    },
    ['textDocument/publishDiagnostics'] = {
    },
    ['textDocument/rangeFormatting'] = {
    },
    ['textDocument/rename'] = {
    },
    ['textDocument/signatureHelp'] = {
    },
    ['typeHierarchy/subtypes'] = {

    },
    ['typeHierarchy/supertypes'] = {

    },
    ['window/logMessage'] = {

    },
    ['window/showDocument'] = {

    },
    ['window/showMessage'] = {

    },
    ['window/showMessageRequest'] = {

    },
    ['window/workDoneProgress/create'] = {

    },
    ['workspace/applyEdit'] = {

    },
    ['workspace/configuration'] = {

    },
    ['workspace/executeCommand'] = {

    },
    ['workspace/inlayHint/refresh'] = {

    },
    ['workspace/semanticTokens/refresh'] = {
    },
    ['workspace/symbol'] = {

    },
    ['workspace/workspaceFolders'] = {

    },
  }
}

--- Configure LSP features
function M.config_handler_features()
  -- Enable inlay hints globally
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.supports_method('textDocument/inlayHint') then
        vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
      end
    end,
  })
end

--- Set up LSP servers using the native API - if available
function M.setup_servers()
  -- https://neovim.io/doc/user/news-0.11.html
  -- https://gpanders.com/blog/whats-new-in-neovim-0-11/
  if M.neovim.has_native_lsp_api then
    return M.config_handler_features()
  end
  print('Neovim version 0.11 or higher is required for native LSP support.')
  print('Please update Neovim to use the latest LSP features.')
end

return M
