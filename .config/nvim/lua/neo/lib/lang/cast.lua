local is_str = require('neo/lib/lang/is_str')
local is_bool = require('neo/lib/lang/is_bool')
local is_num = require('neo/lib/lang/is_num')
local is_func = require('neo/lib/lang/is_func')
local is_table = require('neo/lib/lang/is_table')
local to_str = require('neo/lib/lang/to_str')
local to_bool = require('neo/lib/lang/to_bool')
local to_num = require('neo/lib/lang/to_num')
local to_func = require('neo/lib/lang/to_func')
local to_table = require('neo/lib/lang/to_table')
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
