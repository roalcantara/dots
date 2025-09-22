return {
  --- Enable LSP auto-completion
  --- https://youtu.be/WLauufOgPpo
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  --- https://github.com/mplusp/nvim-0.12-built-in-inline-completion/blob/main/lua/core/lsp.lua
  enable_completion_buffer = function(opts)
    vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'fuzzy', 'popup' }
    vim.lsp.completion.enable(true, opts.client.id, opts.buffer, { autotrigger = true })
    vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get,
      { buffer = opts.buffer, desc = '[' .. tostring(opts.client.name) .. '] Trigger LSP completion (Buffer)' }
    )
  end
}
