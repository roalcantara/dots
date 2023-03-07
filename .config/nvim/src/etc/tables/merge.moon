is_table = require 'etc/lang/is_table'
to_table = require 'etc/lang/to_table'

---Creates a new table concatenating table with any additional table and/or values..
---In case of key/value conflict, the source's value take precedence.
---@param to table The destination table.
---@vararg ... @table The sources to merge.
---@return table result Two or more map-like tables.
merge = (tb, ...) ->
  t = {}
  tb = to_table(tb) unless is_table(tb)
  for k, v in pairs(tb) do t[k] = v
  values = if is_table(...) then ... else to_table(...)
  for k, v in pairs(values) do t[k] = v
  t

return merge
