return {
  -- Toggle inlay hints in the code; which may be unwanted, since they displace some of the code
  --- https://youtu.be/WLauufOgPpo
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  --- https://github.com/mplusp/dotfiles/blob/main/nvim/.config/nvim/lua/plugins/lsp.lua
  toggle_inlay_hints_in_buffer = function(opts)
    vim.schedule_wrap(vim.keymap.set({ 'n', 'i' }, '<leader>th', function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = opts.buffer }))
    end, { buffer = opts.buffer, desc = '[' .. tostring(opts.client.name) .. '] [T]oggle Inlay [H]ints (Buffer)' }))
  end
}
