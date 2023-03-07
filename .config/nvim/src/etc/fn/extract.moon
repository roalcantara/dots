is_nil = require 'etc/lang/is_nil'
is_str = require 'etc/lang/is_str'
is_bool = require 'etc/lang/is_bool'
is_num = require 'etc/lang/is_num'
is_func = require 'etc/lang/is_func'
is_table = require 'etc/lang/is_table'
push = require 'etc/tables/push'
to_table = require 'etc/lang/to_table'
tryCatch = require 'etc/fn/try-catch'

extract_values = (val) ->
  return val if is_str(val) or is_num(val) or is_bool(val) or is_nil(val)
  return extract_values(val()) if is_func(val)
  if is_table(val)
    result = {}
    for key, value in ipairs(val) do
      extracted = extract_values(value)
      if is_num(key) then
        push(result, extracted)
      else
        result[key] = extracted
    return result

--- Extracts arguments from a given object
---@vararg any
---@return table result The extracted arguments
extract = (...) ->
  args = if is_table(...) then ... else to_table(...)
  return tryCatch(() -> return extract_values(args), (e) -> error("error: args: '#{vim.inspect(args)} '#{vim.inspect(e)}"))

return extract
