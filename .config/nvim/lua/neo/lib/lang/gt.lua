local is_str = require('neo/lib/lang/is_str')
local is_num = require('neo/lib/lang/is_num')
local cast = require('neo/lib/lang/cast')
local gt
gt = function(value, other, ...)
  if type(value) == 'nil' or type(other) == 'nil' then
    return false
  end
  value, other = cast(value, other)
  if is_str(value) or is_num(value) then
    return value > other
  end
  if is_str(value) or is_num(value) then
    return value < other
  end
  if type(value) == 'function' and type(other) == 'function' then
    return gt(value(...), other(...))
  end
  return false
end
return gt
