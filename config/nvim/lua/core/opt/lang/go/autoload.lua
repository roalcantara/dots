local bufnr = 19

-- send text to the buffer (running :source %)
vim.api.nvim_create_autocmd('BufWritePost', {
  group = vim.api.nvim_create_augroup('TJCoolTutorial', { clear = true }),
  pattern = 'main.go',
  callback = function()
    vim.fn.jobstart({ 'go', 'run', '/Users/roalcantara/Work/go/vi-demo/main.go' }, {
      stdout_buffered = true,
      on_stdout = function(_, data)
        if data and #data > 0 then
          vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
          Snacks.notify.info('Output from go run main.go: ' .. vim.inspect(data))
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
          Snacks.notify.error('Error from go run main.go: ' .. vim.inspect(data))
        end
      end,
    })
  end,
})
