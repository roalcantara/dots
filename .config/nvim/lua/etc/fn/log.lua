local echohl = vim.schedule_wrap(function(msg, hl)
  local emsg = vim.fn.escape(msg, '"')
  return vim.cmd('echohl ' .. hl .. ' | echom "' .. emsg .. '" | echohl None')
end)
local info
info = function(msg)
  return echohl(msg, 'None')
end
local err
err = function(msg)
  return echohl(msg, 'ErrorMsg')
end
return {
  info = info,
  err = err
}
