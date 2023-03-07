local is_str = require('etc/lang/is_str')
local is_bool = require('etc/lang/is_bool')
local is_num = require('etc/lang/is_num')
local is_func = require('etc/lang/is_func')
local is_table = require('etc/lang/is_table')
local to_str = require('etc/lang/to_str')
local to_bool = require('etc/lang/to_bool')
local to_num = require('etc/lang/to_num')
local to_func = require('etc/lang/to_func')
local to_table = require('etc/lang/to_table')
local cast
cast = function(a, b)
  if type(a) == type(b) then
    return a, b
  end
  if is_str(a) then
    return a, to_str(b)
  end
  if is_bool(a) then
    return a, to_bool(b)
  end
  if is_num(a) then
    return a, to_num(b)
  end
  if is_func(a) then
    return a, to_func(b)
  end
  if is_table(a) then
    return a, to_table(b)
  end
end
return cast
