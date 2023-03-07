echohl = vim.schedule_wrap((msg, hl)->
  emsg = vim.fn.escape(msg, '"')
  vim.cmd('echohl ' .. hl .. ' | echom "' .. emsg .. '" | echohl None')
)

---Logs a message hl [None]
---@param msg string  @ Message
info = (msg)-> echohl(msg, 'None')

---Logs a message hl [ErrorMsg]
---@param msg string  @ Message
err = (msg)-> echohl(msg, 'ErrorMsg')

return {:info, :err}
