local is_func = require('neo/lib/lang/is_func')
local get
get = function(exp, path, defaultValue)
  if defaultValue == nil then
    defaultValue = nil
  end
  if not (is_func(exp)) then
    return vim.fn.get(exp, path, defaultValue)
  end
  if is_func(exp) then
    return vim.fn.get(exp, path)
  end
end
return get
