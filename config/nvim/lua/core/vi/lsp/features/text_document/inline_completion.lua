return {
  --- Enable LLM-based inline completion
  --- https://youtu.be/WLauufOgPpo
  --- https://gpanders.com/blog/whats-new-in-neovim-0-11/#builtin-auto-completion
  --- https://github.com/mplusp/nvim-0.12-built-in-inline-completion/blob/main/lua/core/lsp.lua
  enable_inline_completion_buffer = function(opts)
    local filter = opts.buffer and { bufnr = opts.buffer } or opts.client.id and { client_id = opts.client.id } or {}
    if vim.lsp.inline_completion and not vim.lsp.inline_completion.is_enabled(filter) then
      vim.lsp.inline_completion.enable(true, filter)
      vim.keymap.set('i', '<D-C-CR>', function()
          if not vim.lsp.inline_completion.get() then
            return '<D-C-CR>'
          end
        end,
        {
          buffer = opts.buffer,
          expr = true,
          replace_keycodes = true,
          desc = '[' ..
            tostring(opts.client.name) .. '] Apply the currently displayed completion suggestion (Buffer)'
        }
      )
      vim.keymap.set('i', '<D-C-Right>', function()
          vim.lsp.inline_completion.select({})
        end,
        {
          buffer = opts.buffer,
          desc = '[' ..
            tostring(opts.client.name) .. '] Show next inline completion suggestion (Buffer)'
        }
      )
      vim.keymap.set('i', '<D-C-Left>', function()
          vim.lsp.inline_completion.select({ count = -1 })
        end,
        {
          buffer = opts.buffer,
          desc = '[' ..
            tostring(opts.client.name) .. '] Show previous inline completion suggestion (Buffer)'
        }
      )
    end
  end
}
