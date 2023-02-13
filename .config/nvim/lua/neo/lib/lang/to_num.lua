local is_num = require('neo/lib/lang/is_num')
local is_func = require('neo/lib/lang/is_func')
local is_bool = require('neo/lib/lang/is_bool')
local to_num
to_num = function(value, ...)
  if is_num(value) then
    return value
  end
  if is_bool(value) then
    return value and 1 or 0
  end
  if is_func(value) then
    return to_num(value(...))
  end
end
return to_num
