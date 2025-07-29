local M = {
  --- Enable LSP auto-completion
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  enable_completion = function(opts)
    vim.lsp.completion.enable(true, opts.client.id, opts.buffer, { auto_trigger = true })
  end,
}

return M
