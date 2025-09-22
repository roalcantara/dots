return {
  --- Add normal-mode keymappings for signature help
  --- https://youtu.be/WLauufOgPpo
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  --- https://github.com/mplusp/nvim-0.12-built-in-inline-completion/blob/main/lua/core/lsp.lua
  enable_signature_help_buffer = function(opts)
    vim.schedule_wrap(vim.keymap.set({ 'n', 'i' }, '<D-M-Space>', vim.lsp.buf.signature_help,
      { buffer = opts.buffer, desc = '[' .. tostring(opts.client.name) .. '] Trigger LSP Signature Help (Buffer)' }
    ))
  end
}
