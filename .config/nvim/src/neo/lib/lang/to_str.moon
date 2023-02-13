is_null = require('neo/lib/lang/is_null')
is_num = require('neo/lib/lang/is_num')
is_bool = require('neo/lib/lang/is_bool')
is_func = require('neo/lib/lang/is_func')
is_table = require('neo/lib/lang/is_table')
db_quote = require('neo/lib/strings/db_quote')

---Convert to string
---@return string | table | nil result a string
to_str = (...) ->
  value = ...
  return '' if is_null(value)
  return tostring(value) if type(value) == 'string' or is_num(value) or is_bool(value)
  return type((value())) == 'string' if is_func(value)
  if is_table(value)
    str = '{'
    for k, v in pairs(value) do
      v = type(value) == 'string' and db_quote(v)
      if is_num(k)
        str = tostring(str) .. tostring(v) .. ', '
      else
        str = tostring(str) .. '[' .. tostring(db_quote(k)) .. ']=' .. tostring(v) .. ', '
    return string.sub(str, 0, #str - 2) .. '}'

return to_str
