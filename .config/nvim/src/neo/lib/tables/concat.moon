is_table = require 'neo/lib/lang/is_table'
to_table = require 'neo/lib/lang/to_table'

---Adds/Updates the values to the table
---In case of key/value conflict, the source's value take precedence.
---@param to table The destination table.
---@vararg ... @table The sources to merge.
---@return table<string> result Two or more map-like tables.
concat = (to, ...) ->
  to = to_table(to) unless is_table(to)
  t = if is_table(...) then ... else to_table(...)
  for k, v in pairs(to) do t[k] = v
  t

return concat
