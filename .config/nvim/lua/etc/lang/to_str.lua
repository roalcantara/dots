local is_null = require('etc/lang/is_null')
local is_num = require('etc/lang/is_num')
local is_bool = require('etc/lang/is_bool')
local is_func = require('etc/lang/is_func')
local is_table = require('etc/lang/is_table')
local db_quote = require('etc/strings/db_quote')
local to_str
to_str = function(...)
  local value = ...
  if is_null(value) then
    return ''
  end
  if type(value) == 'string' or is_num(value) or is_bool(value) then
    return tostring(value)
  end
  if is_func(value) then
    return type((value())) == 'string'
  end
  if is_table(value) then
    local str = '{'
    for k, v in pairs(value) do
      v = type(value) == 'string' and db_quote(v)
      if is_num(k) then
        str = tostring(str) .. tostring(v) .. ', '
      else
        str = tostring(str) .. '[' .. tostring(db_quote(k)) .. ']=' .. tostring(v) .. ', '
      end
    end
    return string.sub(str, 0, #str - 2) .. '}'
  end
end
return to_str
