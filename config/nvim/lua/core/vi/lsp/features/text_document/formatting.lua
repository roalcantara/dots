return {
  --- Add auto-format on save
  --- https://youtu.be/WLauufOgPpo
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  --- https://github.com/mplusp/nvim-0.12-built-in-inline-completion/blob/main/lua/core/lsp.lua
  enable_auto_format_on_save_buffer = vim.schedule_wrap(function(opts)
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = opts.buffer,
      callback = function()
        vim.lsp.buf.format({ bufnr = opts.buffer, id = opts.client.id })
      end,
      group = opts.augroup('on_buf_write_pre_lsp_autoformat_' ..
        tostring(opts.client.name) .. '_' .. tostring(opts.buffer)),
      desc = '[' .. tostring(opts.client.name) .. '] Auto format on save (Buffer)',
    })
  end)
}
