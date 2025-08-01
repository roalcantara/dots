--- Execute a function on <Esc>
--- @param opts table { on_esc: function, desc: string? } | Function to be executed on <Esc> and optional description
--- @return function (event: table) -> nil event executed on <Esc>
local execute_on_esc = function(opts)
  return function(event)
    if not event then
      event = { buf = vim.api.nvim_get_current_buf() }
    end
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(event.buf) then
        vim.keymap.set('n', '<esc>', function()
          opts.on_esc(event)
        end, {
          buffer = event.buf,
          silent = true,
          desc = opts.desc or '<Esc> triggered!',
        })
      end
    end)
  end
end

return execute_on_esc
