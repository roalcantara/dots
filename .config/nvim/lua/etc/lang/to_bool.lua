local is_nil = require('etc/lang/is_nil')
local is_bool = require('etc/lang/is_bool')
local is_str = require('etc/lang/is_str')
local is_num = require('etc/lang/is_num')
local is_func = require('etc/lang/is_func')
local to_bool
to_bool = function(value, ...)
  if is_nil(value) then
    return false
  end
  if is_bool(value) then
    return value
  end
  if is_str(value) then
    return #value > 0
  end
  if is_num(value) then
    return value ~= 0
  end
  if type(value) ~= 'nil' and is_func(value) then
    return to_bool(value(...))
  end
  return false
end
return to_bool
