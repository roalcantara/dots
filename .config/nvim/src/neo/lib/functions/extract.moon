is_nil = require 'neo/lib/lang/is_nil'
is_str = require 'neo/lib/lang/is_str'
is_bool = require 'neo/lib/lang/is_bool'
is_num = require 'neo/lib/lang/is_num'
is_func = require 'neo/lib/lang/is_func'
is_table = require 'neo/lib/lang/is_table'
push = require 'neo/lib/tables/push'
to_table = require 'neo/lib/lang/to_table'
tryCatch = require 'neo/lib/functions/try-catch'

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
